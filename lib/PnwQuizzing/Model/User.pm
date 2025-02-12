package PnwQuizzing::Model::User;

use exact -class, -conf;
use Mojo::JSON qw( encode_json decode_json );
use Mojo::Util qw( b64_encode b64_decode );
use Omniframe::Util::Bcrypt 'bcrypt';
use Omniframe::Util::Crypt qw( encrypt decrypt );
use PnwQuizzing::Model::Email;

with 'Omniframe::Role::Model';

class_has active => 1;

before 'create' => sub ( $self, $params ) {
    $params->{active} //= 0;
};

sub freeze ( $self, $data ) {
    $data->{org_id} = delete $data->{org} if ( exists $data->{org} );

    my $min_passwd_length = conf->get('min_passwd_length');
    if ( $self->is_dirty( 'passwd', $data ) ) {
        croak("Password supplied is not at least $min_passwd_length characters in length")
            unless ( length $data->{passwd} >= $min_passwd_length );
        $data->{passwd} = bcrypt( $data->{passwd} );
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

sub _encode_token ($user_id) {
    return b64_encode( encrypt( encode_json( [ $user_id, time ] ) ) );
}

sub _decode_token ($token) {
    my $data;
    try {
        $data = decode_json( decrypt( b64_decode($token) ) );
    }
    catch ($e) {}

    return (
        $data and $data->[0] and $data->[1] and
        $data->[1] < time + conf->get('token_expiration')
    ) ? $data->[0] : undef;
}

sub verify_email ( $self, $url = undef ) {
    croak('Cannot verify_email() because user data not loaded in user object') unless ( $self->data );
    $url ||= conf->get('base_url');
    $url .= '/user/verify/' . _encode_token( $self->id );

    PnwQuizzing::Model::Email->new( type => 'verify_email' )->send({
        to   => sprintf( '%s %s <%s>', map { $self->data->{$_} } qw( first_name last_name email ) ),
        data => {
            %{ $self->data },
            url => $url,
        },
    });

    return;
}

sub verify ( $self, $token ) {
    my $user_id = _decode_token($token);
    return unless ($user_id);

    $self->dq->sql('UPDATE user SET active = 1 WHERE user_id = ?')->run($user_id);
    return $user_id;
}

sub login ( $self, $username, $passwd ) {
    for ( qw( username passwd ) ) {
        croak( qq{"$_" appears to not be a valid input value} ) unless ( length $_ );
    }

    $passwd = bcrypt($passwd);

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
    $url .= '/user/reset_password/' . _encode_token( $user->id );

    PnwQuizzing::Model::Email->new( type => 'reset_password' )->send({
        to   => sprintf( '%s %s <%s>', map { $user->data->{$_} } qw( first_name last_name email ) ),
        data => {
            %{ $user->data },
            url => $url,
        },
    });

    return;
}

sub reset_password_check ( $self, $token ) {
    my $user_id = _decode_token($token);
    croak('Unable to locate active user') unless ($user_id);
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
