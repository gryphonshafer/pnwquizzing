package PnwQuizzing::Model::User;

use exact -conf, -class;
use Mojo::JSON qw( encode_json decode_json );
use PnwQuizzing::Model::Email;

with qw( Omniframe::Role::Model Omniframe::Role::Bcrypt );

class_has active => 1;

before 'create' => sub ( $self, $params ) {
    $params->{active} //= 0;
};

sub freeze ( $self, $data ) {
    $data->{org_id} = delete $data->{org} if ( exists $data->{org} );

    if ( $data->{passwd} ) {
        croak('Password supplied is not at least 6 characters in length')
            unless ( length $data->{passwd} >= 6 );
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
    $url ||= $self->conf->get('base_url');
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
    catch {
        $self->info('Login failure (in model)');
        croak('Failed user login');
    };

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

    $url ||= $self->conf->get('base_url');
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

sub reset_password ( $self, $user_id, $passwd ) {
    croak('Unable to locate active user given user ID and password provided') unless (
        $self->dq->sql(q{
            SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ? AND active
        })->run( $user_id, $passwd . '%' )->value
    );

    my $user = PnwQuizzing::Model::User->new->load($user_id);
    my $new_passwd = substr( $self->bcrypt( $$ . time() . rand() ), 0, 12 );

    return $user->save( { passwd => $new_passwd, active => 1 } );
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

=head2 reset_password

Reset a user's password in resposne to a reset password email response.
