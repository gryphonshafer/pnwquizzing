package PnwQuizzing::Model::Entry;

use exact -conf, -class;
use Mojo::JSON qw( encode_json decode_json );

with 'Omniframe::Role::Model';

sub freeze ( $self, $data ) {
    $data->{registration} = encode_json( $data->{registration} );
    return $data;
}

sub thaw ( $self, $data ) {
    $data->{registration} = ( $data->{registration} ) ? decode_json( $data->{registration} ) : undef;
    return $data;
}

sub _decode_registrations ($entries) {
    return [ map {
        $_->{registration} = decode_json $_->{registration};
        $_;
    } @$entries ];
}

sub user_registrations ( $self, $meet_id, $user_id = undef ) {
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
            WHERE meet_id = ? AND org_id IS NULL } . (
                ($user_id)
                    ? ( 'AND user_id = ' . $self->dq->quote($user_id) )
                    : ''
            ) . q{
            ORDER BY created DESC
        ) AS e
        JOIN user AS u USING (user_id)
        LEFT JOIN org AS o ON u.org_id = o.org_id AND o.active
        WHERE u.active
        GROUP BY user_id
        ORDER BY o.acronym, u.first_name, u.last_name
    })->run($meet_id)->all({});
}

sub org_registrations ( $self, $meet_id, $org_id = undef ) {
    return _decode_registrations $self->dq->sql(q{
        SELECT
            e.org_id,
            e.registration,
            e.created,
            o.name,
            o.acronym
        FROM (
            SELECT org_id, registration, created
            FROM entry
            WHERE meet_id = ? AND } . (
                ($org_id)
                    ? ( 'org_id = ' . $self->dq->quote($org_id) )
                    : 'org_id IS NOT NULL'
            ) . q{
            ORDER BY created DESC
        ) AS e
        JOIN org AS o USING (org_id)
        WHERE o.active
        GROUP BY org_id
        ORDER BY o.acronym
    })->run($meet_id)->all({});
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
