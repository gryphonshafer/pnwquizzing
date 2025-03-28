package PnwQuizzing::Model::Entry;

use exact -class, -conf;
use Mojo::JSON qw( to_json from_json );
use DateTime;

with 'Omniframe::Role::Model';

sub freeze ( $self, $data ) {
    $data->{registration} = to_json( $data->{registration} );
    return $data;
}

sub thaw ( $self, $data ) {
    $data->{registration} = ( $data->{registration} ) ? from_json( $data->{registration} ) : undef;
    return $data;
}

sub _decode_registrations ($entries) {
    return [ map {
        $_->{registration} = from_json $_->{registration};
        $_;
    } @$entries ];
}

sub _season_break_timestamp {
    my $now = DateTime->now->set_time_zone( conf->get('time_zone') );

    my $season_break = DateTime->new(
        %{ conf->get('season_break') },
        year      => $now->year,
        time_zone => conf->get('time_zone'),
    );

    $season_break->subtract( years => 1 ) if ( $now->epoch < $season_break->epoch );

    return $season_break->set_time_zone('Zulu') . '.000Z';
}

sub user_registrations ( $self, $user_id = undef ) {
    return _decode_registrations $self->dq->sql(q{
        SELECT
            e.user_id,
            e.registration,
            e.created,
            u.first_name,
            u.last_name,
            u.email,
            u.roles,
            u.last_login,
            o.name,
            o.acronym
        FROM (
            SELECT user_id, registration, created
            FROM entry
            WHERE org_id IS NULL AND created >= ? } . (
                ($user_id)
                    ? ( 'AND user_id = ' . $self->dq->quote($user_id) )
                    : ''
            ) . q{
            ORDER BY created DESC
            LIMIT 9223372036854775807 -- hack to force SQLite to respect DESC
        ) AS e
        JOIN user AS u USING (user_id)
        LEFT JOIN org AS o ON u.org_id = o.org_id AND o.active
        WHERE u.active AND NOT u.dormant
        GROUP BY user_id
        ORDER BY o.acronym, u.first_name, u.last_name
    })->run( _season_break_timestamp )->all({});
}

sub org_registrations ( $self, $org_id = undef ) {
    return _decode_registrations $self->dq->sql(q{
        SELECT
            e.org_id,
            e.registration,
            e.created,
            o.name,
            o.acronym,
            o.address
        FROM (
            SELECT org_id, registration, created
            FROM entry
            WHERE created >= ? AND } . (
                ($org_id)
                    ? ( 'org_id = ' . $self->dq->quote($org_id) )
                    : 'org_id IS NOT NULL'
            ) . q{
            ORDER BY created DESC
            LIMIT 9223372036854775807 -- hack to force SQLite to respect DESC
        ) AS e
        JOIN org AS o USING (org_id)
        WHERE o.active
        GROUP BY org_id
        ORDER BY o.acronym
    })->run( _season_break_timestamp )->all({});
}

1;

=head1 NAME

PnwQuizzing::Model::Entry

=head1 DESCRIPTION

This model provides functionality for entry objects.

=head1 METHODS

=head2 freeze

Freeze "registration" hash prior to database save.

=head2 thaw

Thaw "registration" hash after database load.

=head2 user_registrations

SQL call to return an arrayref of hashrefs of user registrations.

=head2 org_registrations

SQL call to return an arrayref of hashrefs of organization (teams/quizzers)
registrations.
