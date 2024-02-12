package PnwQuizzing::Control::User;

use exact -conf, 'Mojolicious::Controller';
use Mojo::JSON 'encode_json';
use PnwQuizzing::Model::User;
use PnwQuizzing::Model::Org;

sub account ($self) {
    if ( $self->param('form_submit') ) {
        my $params = $self->req->params->to_hash;

        try {
            die 'Username, password, first and last name, and email fields must be filled in' unless (
                $params->{username} and
                $params->{first_name} and
                $params->{last_name} and
                $params->{email}
            );

            die 'Email entry does not appear to be a valid email address'
                unless ( $params->{email} =~ /\w+@\w+\.\w+/ );

            if ( $params->{org} ) {
                die 'Organization was not selected and is required'
                    if ( $params->{org} eq '_NOT_DEFINED' );
                delete $params->{org} if ( $params->{org} eq '_NEW_ORG' );
            }

            unless ( $self->stash('user') ) {
                $self->_recaptcha;

                my $user = PnwQuizzing::Model::User->new->create( { map { $_ => $params->{$_} } qw(
                    username passwd first_name last_name email org roles
                ) } );

                if ( $user and $user->data ) {
                    my $url = $self->req->url->to_abs;
                    $user->verify_email( $url->protocol . '://' . $url->host_port );
                    $self->stash( successful_create_user => 1 );
                }
            }
            else {
                $self->stash('user')->save( {
                    dormant => ( ( $params->{dormant} and $params->{dormant} eq 'on' ) ? 1 : 0 ),
                    roles   => [ ( ref $params->{roles} ) ? @{ $params->{roles} } : $params->{roles} ],
                    map { $_ => $params->{$_} } qw( username first_name last_name email org ),
                } );

                $self->stash('user')->save( { passwd => $params->{passwd} } ) if ( $params->{passwd} );

                $self->stash(
                    message => {
                        type => 'success',
                        text => 'Successfully edited site account profile.',
                    }
                );
            }
        }
        catch ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
            $e =~ s/DBD::\w+::st execute failed:\s*//;
            $e .= '. Please try again.';

            $e = "Value in $1 field is already registered under an existing user account."
                if ( $e =~ /UNIQUE constraint failed/ );

            $self->info('User CRUD failure');
            $self->stash( message => $e, %$params );
        }
    }

    my $user_org_id = ( $self->stash('user') ) ? $self->stash('user')->data->{org_id} || undef : undef;
    my $user_roles  = ( $self->stash('user') ) ? $self->stash('user')->data->{roles} || [] : [];

    $self->stash(
        orgs => [ map {
            $_->{has_org} = 1 if ( $user_org_id and $user_org_id == $_->{org_id} );
            $_;
        } sort { $a->{acronym} cmp $b->{acronym} } @{ PnwQuizzing::Model::Org->new->every_data } ],

        roles => [
            map {
                my $name = $_;
                +{
                    name     => $name,
                    has_role => scalar( grep { $name eq $_ } @$user_roles ),
                }
            } @{ conf->get('roles') }
        ],
    );
}

sub verify ($self) {
    if (
        PnwQuizzing::Model::User->new->verify(
            $self->stash('verify_user_id'),
            $self->stash('verify_passwd'),
        )
    ) {
        $self->flash(
            message => {
                type => 'success',
                text => 'Successfully verified this user account. Please now login with your credentials.',
            }
        );
    }
    else {
        $self->flash( message => 'Unable to verify user account using the link provided.' );
    }

    return $self->redirect_to('/');
}

sub login ($self) {
    my $user = PnwQuizzing::Model::User->new;

    my $redirect;
    try {
        $user = $user->login( map { $self->param($_) } qw( username passwd ) );
    }
    catch ($e) {
        $self->info('Login failure (in controller)');
        $self->flash( message =>
            'Login failed. Please try again, or try the ' .
            '<a href="' . $self->url_for('/user/reset_password') . '">Reset Password page</a>.'
        );
        $redirect = 1;
    }
    return $self->redirect_to('/') if ($redirect);

    $self->info( 'Login success for: ' . $user->data->{username} );
    $self->session(
        user_id           => $user->id,
        last_request_time => time,
    );

    return $self->redirect_to('/');
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->data->{username} : '(Unlogged-in user)' )
    );
    $self->session(
        user_id           => undef,
        last_request_time => undef,
    );

    return $self->redirect_to('/');
}

sub reset_password ($self) {
    my $redirect = sub {
        $self->flash(
            message => {
                type => 'success',
                text => join( ' ',
                    'You are now logged in; however, your password is not yet reset.',
                    'Use the edit profile page to change your password to something new.',
                ),
            }
        );

        return $self->redirect_to('/user/account');
    };

    return $redirect->() if ( $self->stash('user') );

    if ( $self->param('username') or $self->param('email') ) {
        $self->_recaptcha;

        my $url = $self->req->url->to_abs;
        try {
            PnwQuizzing::Model::User->new->reset_password_email(
                $self->param('username'),
                $self->param('email'),
                $url->protocol . '://' . $url->host_port,
            );
            $self->stash(
                message => {
                    type => 'success',
                    text => 'Successfully send a reset password confirmation email.',
                }
            );
        }
        catch ($e) {
            $self->warn( $e->message );
            $self->stash( message => 'Unable to locate user account using the input values provided.' );
        };
    }
    elsif ( $self->param('form_post') ) {
        $self->stash( message => 'Unable to locate user account using the input values provided.' );
    }
    elsif ( $self->stash('reset_user_id') and $self->stash('reset_passwd') ) {
        try {
            my $user = PnwQuizzing::Model::User->new->reset_password_check(
                $self->stash('reset_user_id'),
                $self->stash('reset_passwd'),
            );

            $self->info( 'Login success for: ' . $user->data->{username} );
            $self->session(
                user_id           => $user->id,
                last_request_time => time,
            );

            return $redirect->();
        }
        catch ($e) {
            $self->warn( $e->message );
            $self->stash( message =>
                'Unable to verify user account for reset user password action. ' .
                'Note the time and email site administration for assistance.'
            );
        };
    }
}

sub list ($self) {
    $self->stash(
        list_data => encode_json( {
            roles => [ map { +{ name => $_, selected => 0 } } @{ conf->get('roles') } ],
            users => [
                sort {
                    $a->{first_name} cmp $b->{first_name} or
                    $a->{last_name} cmp $b->{last_name}
                }
                map {
                    $_->{email} = lc $_->{email};

                    $_->{org} = PnwQuizzing::Model::Org->new
                        ->load( $_->{org_id}, 'include_inactive' )->data if ( $_->{org_id} );

                    $_;
                } PnwQuizzing::Model::User->new->every_data({ dormant => 0 })
            ],
            cnp_email_list => 0,
        } ),
    );
}

sub org ($self) {
    my $org = PnwQuizzing::Model::Org->new;
    $org->load( $self->stash('user')->data->{org_id} ) if ( $self->stash('user')->data->{org_id} );

    unless ( $self->param('form_submit') ) {
        $self->stash( org => $org );
    }
    else {
        my $params = $self->req->params->to_hash;

        try {
            die 'Full name, acronym, and address fields must be filled in' unless (
                $params->{name} and
                $params->{acronym} and
                $params->{address}
            );

            unless ( $org->data ) {
                $org->create({ map { $_ => $params->{$_} } qw( name acronym address ) });
                $self->stash('user')->save({ org_id => $org->id });
            }
            else {
                $org
                    ->load( $self->stash('user')->data->{org_id} )
                    ->save({ map { $_ => $params->{$_} } qw( name acronym address ) });
            }

            $self->redirect_to('/user/account');
        }
        catch ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
            $e =~ s/DBD::\w+::st execute failed:\s*//;
            $e .= '. Please try again.';

            $e = "Value in $1 field is already registered under an existing organization."
                if ( $e =~ /UNIQUE constraint failed/ );

            $self->info('Org CRUD failure');
            $self->stash( message => $e, %$params );
        }
    }
}

sub become ($self) {
    unless ( $self->param('username') ) {
        $self->stash( users => [
            sort {
                $b->{active} <=> $a->{active} or
                $a->{dormant} <=> $b->{dormant} or
                $a->{first_name} cmp $b->{first_name} or
                $a->{last_name} cmp $b->{last_name}
            } PnwQuizzing::Model::User->every_data({ active => \q( IS NOT NULL ) })
        ] );
    }
    else {
        $self->session( become => $self->param('username') );
        $self->redirect_to('/user/account');
    }
}

sub unbecome ($self) {
    $self->session( become => undef );
    $self->redirect_to('/user/account');
}

sub _recaptcha ($self) {
    if ( my $recaptcha_secret_key = $self->app->conf->get( qw( recaptcha secret_key ) ) ) {
        my $site_verify = $self->ua->post(
            'https://www.google.com/recaptcha/api/siteverify',
            form => {
                secret   => $recaptcha_secret_key,
                response => $self->param('g-recaptcha-response'),
            },
        )->result->json;

        $self->info( 'Recaptcha site verify score: ' . ( $site_verify->{score} // '>>undef<<' ) );

        die 'Human-verification score too low. Please wait for the page to fully low, then try again'
            unless (
                $site_verify and
                $site_verify->{score} and
                $site_verify->{score} > $self->app->conf->get( qw( recaptcha min_score ) ) // 0.5
            );
    }

    return;
}

1;

=head1 NAME

PnwQuizzing::Control::User

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "user" actions.

=head1 METHODS

=head2 account

Handler for "account" calls.

=head2 verify

Handler for "verify" calls.

=head2 login

Handler for "login" calls.

=head2 logout

Handler for "logout" calls.

=head2 reset_password

Handler for "reset_password" calls.

=head2 list

Handler for "list" calls.

=head2 org

Handler for "org" calls.

=head2 become

Administrator users can become another user.

=head2 unbecome

After becoming a user via C<become>, this returns the user to their original
state.

=head1 INHERITANCE

L<Mojolicious::Controller>.
