package PnwQuizzing::Control;

use exact -conf, 'Omniframe::Control';
use Mojo::File;

sub startup ($self) {
    $self->setup_mojo_logging;

    $self->plugin('RequestBase');
    $self->sass->build;

    $self->setup_access_log;
    $self->setup_templating;
    $self->setup_static_paths;
    $self->setup_config;
    $self->setup_packer;
    $self->setup_compressor;
    $self->setup_document;
    $self->setup_devdocs;

    $self->preload_controllers;

    my $root_dir = conf->get( qw( config_app root_dir ) );
    my $photos   = Mojo::File
        ->new( $root_dir . '/static/photos' )
        ->list_tree
        ->map( sub { substr( $_->to_string, length( $root_dir . '/static' ) ) } )
        ->grep(qr/\.(?:jpg|png)$/)
        ->to_array;

    my $all = $self->routes->under( sub ($self) {
        if ( my $user_id = $self->session('user_id') ) {
            my $user;
            try {
                $user = PnwQuizzing::Model::User->new->load($user_id);
            }
            catch {
                $self->notice( 'Failed user load based on session "user_id" value: "' . $user_id . '"' );
            };

            if ($user) {
                $self->stash( 'user' => $user );

                return $self->redirect_to('/user/org') if (
                    not $user->data->{org_id}
                    and $self->req->url->path ne '/user/org'
                    and $self->req->url->path ne '/user/logout'
                );
            }
            else {
                delete $self->session->{'user_id'};
            }
        }

        $self->stash(
            docs_nav      => $self->docs_nav( @{ conf->get('docs') }{ qw( dir home_type home_title ) } ),
            header_photos => $photos,
        );
    } );

    my $users = $all->under( sub ($self) {
        return 1 if ( $self->stash('user') );
        $self->info('Login required but not yet met');
        $self->flash( message => 'Login required for the previously requested resource.' );
        $self->redirect_to('/');
        return 0;
    } );

    $users->any( '/tool/' . $_ )->to( controller => 'tool', action => $_ ) for ( qw(
        register
        register_save
        meet_data
    ) );
    $users->any( '/tool/meet_data' => [ format => 'csv' ] )->to('tool#meet_data');
    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( logout list org ) );

    $all->any('/user/verify/:verify_user_id/:verify_passwd')->to('user#verify');
    $all->any('/user/reset_password/:reset_user_id/:reset_passwd')->to('user#reset_password');
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
