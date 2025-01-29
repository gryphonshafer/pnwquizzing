package PnwQuizzing::Model::User;

use exact -class, -conf;
use Mojo::JSON qw( encode_json decode_json );
use PnwQuizzing::Model::Email;

with qw( Omniframe::Role::Model Omniframe::Role::Bcrypt );

class_has active => 1;

my $min_passwd_length = 6;

before 'create' => sub ( $self, $params ) {
    $params->{active} //= 0;
};

sub freeze ( $self, $data ) {
    $data->{org_id} = delete $data->{org} if ( exists $data->{org} );

    if ( $self->is_dirty( 'passwd', $data ) ) {
        croak("Password supplied is not at least $min_passwd_length characters in length")
            unless ( length $data->{passwd} >= $min_passwd_length );
        $data->{passwd} = $self->bcrypt( $data->{passwd} );
    }

    $data->{roles} = encode_json(
        [ ( ref $data->{roles} ) ? @{ $data->{roles} } : $data->{roles} ]
    ) if ( $data->{roles} );

    return $data;
}

sub thaw ( $self, $data ) {
    $data->{roles} = ( $data->{roles} ) ? decode_json( $data->{roles} ) : [];
    $data->{roles} = [ $data->{roles} ] unless ( ref $data->{roles} );

    return $data;
}

sub verify_email ( $self, $url = undef ) {
    croak('Cannot verify_email() because user data not loaded in user object') unless ( $self->data );
    $url ||= conf->get('base_url');
    $url .= '/user/verify/' . $self->id . '/' . substr( $self->data->{passwd}, 0, 12 );

    PnwQuizzing::Model::Email->new( type => 'verify_email' )->send({
        to   => sprintf( '%s %s <%s>', map { $self->data->{$_} } qw( first_name last_name email ) ),
        data => {
            %{ $self->data },
            url => $url,
        },
    });

    return;
}

sub verify ( $self, $user_id, $passwd ) {
    my $verified = $self->dq->sql(q{
        SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ?
    })->run( $user_id, $passwd . '%' )->value;

    $self->dq->sql('UPDATE user SET active = 1 WHERE user_id = ?')->run($user_id) if ($verified);
    return $verified;
}

sub login ( $self, $username, $passwd ) {
    for ( qw( username passwd ) ) {
        croak( qq{"$_" appears to not be a valid input value} ) unless ( length $_ );
    }

    $passwd = $self->bcrypt($passwd);

    try {
        $self->load( { username => $username, passwd => $passwd, active => 1 } );
        $self->save( { last_login => \q{ DATETIME('NOW') } } );
    }
    catch ($e) {
        $self->info('Login failure (in model)');
        croak('Failed user login');
    }

    return $self;
}

sub reset_password_email ( $self, $username = '', $email = '', $url = undef ) {
    my $user_id = $self->dq->sql(q{
        SELECT user_id
        FROM user
        WHERE LOWER(username) = ? OR LOWER(email) = ?
    })->run( lc($username), lc($email) )->value;

    croak('Failed to find user based on username or email') unless ($user_id);

    my $user = PnwQuizzing::Model::User->new->load($user_id);

    $url ||= conf->get('base_url');
    $url .= '/user/reset_password/' . $user->id . '/' . substr( $user->data->{passwd}, 0, 12 );

    PnwQuizzing::Model::Email->new( type => 'reset_password' )->send({
        to   => sprintf( '%s %s <%s>', map { $user->data->{$_} } qw( first_name last_name email ) ),
        data => {
            %{ $user->data },
            url => $url,
        },
    });

    return;
}

sub reset_password_check ( $self, $user_id, $passwd ) {
    croak('Unable to locate active user given user ID and password provided') unless (
        $self->dq->sql(q{
            SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ? AND active
        })->run( $user_id, $passwd . '%' )->value
    );

    return PnwQuizzing::Model::User->new->load($user_id);
}

sub is_admin ( $self, $user_id = undef ) {
    croak('Must have loaded user data or pass in a user ID') unless ( $self->data or $user_id );

    my $username = ( $self->data )
        ? $self->data->{username}
        : $self->dq->sql(q{
            SELECT username FROM user WHERE active AND NOT dormant AND user_id = ?
        })->run($user_id)->value;

    return 0 unless ($username);
    return ( grep { $username eq $_ } map { $_ || '' } @{ conf->get('admins') || [] } ) ? 1 : 0;
}

1;

=head1 NAME

PnwQuizzing::Model::User

=head1 DESCRIPTION

This model provides functionality for user objects.

=head1 METHODS

=head2 freeze

Freeze the "roles" hashref and hash the "passwd" value before database save.

=head2 thaw

Thaw the "roles" hashref after database load.

=head2 verify_email

Send a verify email to a user.

=head2 verify

Response to a verify response from a verify email.

=head2 login

User login.

=head2 reset_password_email

Send a reset password email to a user.

=head2 reset_password_check

Check validity of a reset password link from a reset password email.

=head2 is_admin

Returns 1 or 0 whether the loaded user is an administrator, defined by the
"admins" array of usernames in the configuration. This method also optionally
accepts a user ID.
