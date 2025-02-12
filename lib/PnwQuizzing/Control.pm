package PnwQuizzing::Control;

use exact -conf, 'Omniframe::Control';
use Mojo::File;
use Omniframe::Util::File 'opath';

sub startup ($self) {
    $self->setup( skip => ['sockets'] );

    my $captcha_conf = conf->get('captcha');
    $captcha_conf->{ttf} = opath( $captcha_conf->{ttf} );
    $self->plugin( CaptchaPNG => $captcha_conf );

    my $root_dir = conf->get( qw( config_app root_dir ) );
    my $photos   = Mojo::File
        ->new( $root_dir . '/static/photos' )
        ->list_tree
        ->map( sub { substr( $_->to_string, length( $root_dir . '/static' ) ) } )
        ->grep(qr/\.(?:jpg|png)$/)
        ->to_array;

    my $all = $self->routes->under( sub ($c) {
        if ( my $user_id = $c->session('user_id') ) {
            my $user;

            unless ( my $become = $c->session('become') ) {
                try {
                    $user = PnwQuizzing::Model::User->new->load($user_id);
                }
                catch ($e) {
                    $c->notice( 'Failed user load based on session "user_id" value: "' . $user_id . '"' );
                };
            }
            else {
                try {
                    $user = PnwQuizzing::Model::User->new->load({ username => $become });
                }
                catch ($e) {
                    $c->notice( 'Failed user load based on "become" username value: "' . $become . '"' );
                    $c->flash( memo => {
                        class   => 'error',
                        message => 'Failed to become user: "' . $become . '"',
                    } );
                    $c->session( become => undef );
                    $c->redirect_to('/user/account');
                };
            }

            if ($user) {
                $c->stash( 'user' => $user );

                return $c->redirect_to('/user/org') if (
                    not $c->session('become')
                    and not $user->data->{org_id}
                    and $c->req->url->path ne '/user/org'
                    and $c->req->url->path ne '/user/logout'
                );
            }
            else {
                delete $c->session->{'user_id'};
            }
        }

        $c->stash(
            docs_nav      => $c->docs_nav( @{ conf->get('docs') }{ qw( dir home_type home_name home_title ) } ),
            header_photos => $photos,
        );
    } );

    my $users = $all->under( sub ($c) {
        return 1 if ( $c->stash('user') );
        $c->info('Login required but not yet met');
        $c->flash( memo => {
            class   => 'error',
            message => 'Login required for the previously requested resource.',
        } );
        $c->redirect_to('/');
        return 0;
    } );

    $users->any( '/tool/' . $_ )->to( controller => 'tool', action => $_ ) for ( qw(
        register
        register_save
        meet_data
    ) );
    $users->any( '/tool/meet_data' => [ format => 'csv' ] )->to('tool#meet_data');
    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( logout list org unbecome ) );

    $users->under( sub ($c) {
        return 1 if ( $c->stash('user')->is_admin );
        $c->info('Admin required but not met');
        $c->flash( memo => {
            class   => 'error',
            message => 'Administrator access required for the previously requested resource.',
        } );
        $c->redirect_to('/');
        return 0;
    } )->any('/user/become')->to('user#become');

    $all->any("/user/$_/:token")->to("user#$_") for ( qw( verify reset_password ) );
    $all->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( account login reset_password ) );
    $all->any('/search')->to('tool#search');
    $all->any('/')->to('main#home_page');
    $all->any('/*name')->to('main#content');
}

1;

=head1 NAME

PnwQuizzing::Control

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use MojoX::ConfigAppStart;
    MojoX::ConfigAppStart->start;

=head1 DESCRIPTION

This class is a subclass of L<Omniframe::Control> and provides an override to
the C<startup> method such that L<MojoX::ConfigAppStart> (along with its
required C<mojo_app_lib> configuration key) is sufficient to startup a basic
(and mostly useless) web application.

=head1 METHODS

=head2 startup

This is a basic, thin startup method for L<Mojolicious>. This method calls
C<setup> and sets a universal route that renders a basic text message.

=head1 INHERITANCE

L<Omniframe::Control>.
