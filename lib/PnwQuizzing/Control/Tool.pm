package PnwQuizzing::Control::Tool;

use exact -conf, 'Mojolicious::Controller';
use File::Find 'find';
use Mojo::JSON qw( to_json from_json );
use Text::CSV_XS 'csv';
use PnwQuizzing::Model::Meet;
use PnwQuizzing::Model::Org;
use PnwQuizzing::Model::Entry;

sub search ($self) {
    my $docs_dir = conf->get( qw( config_app root_dir ) ) . '/' . conf->get( qw( docs dir ) );

    my @files;
    find(
        {
            wanted => sub {
                push( @files, $File::Find::name ) if (
                    /\.(?:md|csv)$/i
                );
            },
        },
        $docs_dir,
    );

    my $for    = quotemeta( $self->param('for') );
    my $length = length $docs_dir;

    $self->stash(
        files => [
            map {
                my $path = substr( $_, $length );
                ( my $name = substr( $path, 1 ) ) =~ s/\.\w+$//;

                {
                    path  => $path,
                    title => [
                        map {
                            ucfirst( join( ' ', map {
                                ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
                            } split('_') ) )
                        } split( '/', $name )
                    ],
                }
            } grep {
                my $content = Mojo::File->new($_)->slurp('UTF-8');
                $content =~ /$for/msi;
            } @files
        ],
    );
}

sub register ($self) {
    return $self->redirect_to('/') if (
        $self->stash('user')->data->{dormant} or
        grep { $_ eq 'Quizzer' } @{ $self->stash('user')->data->{roles} }
    );

    my $user_reg = PnwQuizzing::Model::Entry->user_registrations( $self->stash('user')->id             );
    my $org_reg  = PnwQuizzing::Model::Entry->org_registrations ( $self->stash('user')->data->{org_id} );

    $self->stash(
        next_meet     => PnwQuizzing::Model::Meet->next_meet_data,
        register_data => to_json( {
            meet_roles    => conf->get('meet_roles'),
            bibles        => conf->get('bibles'),
            profile_coach => ( grep { $_ eq 'Coach' } @{ $self->stash('user')->data->{roles} } ) ? 1 : 0,
            changed       => 0,
            org           => (
                ( $self->stash('user')->data->{org_id} )
                    ? PnwQuizzing::Model::Org->new->load( $self->stash('user')->data->{org_id} )->data
                    : undef
            ),

            attend      => 0,
            roles       => [],
            drive       => 0,
            house       => 0,
            lunch       => 0,
            notes       => '',
            nonquizzers => [],
            %{
                (
                    $user_reg and
                    $user_reg->[0] and
                    $user_reg->[0]{registration}
                ) ? $user_reg->[0]{registration} : {
                    attend      => 0,
                    roles       => [],
                    drive       => 0,
                    house       => 0,
                    lunch       => 0,
                    notes       => '',
                    nonquizzers => [],
                }
            },

            teams => (
                (
                    $org_reg and
                    $org_reg->[0] and
                    $org_reg->[0]{registration}
                ) ? $org_reg->[0]{registration} : [],
            ),
        } ),
    );
}

sub register_save ($self) {
    my $next_meet = PnwQuizzing::Model::Meet->next_meet_data;

    unless ( $next_meet->{past_deadline} and not $self->session('become') ) {
        my $data = from_json( $self->param('data') );

        PnwQuizzing::Model::Entry->new->create({
            meet_id      => $next_meet->{meet_id},
            user_id      => $self->stash('user')->id,
            registration => { map { $_ => $data->{$_} } qw(
                attend drive house lunch roles notes nonquizzers
            ) },
        });

        PnwQuizzing::Model::Entry->new->create({
            meet_id      => $next_meet->{meet_id},
            user_id      => $self->stash('user')->id,
            org_id       => $self->stash('user')->data->{org_id},
            registration => $data->{teams},
        }) if ( $data->{teams} );

        $self->flash(
            memo => {
                class   => 'success',
                message => 'Successfully saved registration data.',
            }
        );
    }
    else {
        $self->flash( memo => { class => 'error', message => 'Unable to register after deadline.' } );
    }

    return $self->redirect_to('/tool/meet_data')
}

sub meet_data ($self) {
    my $next_meet = PnwQuizzing::Model::Meet->next_meet_data;
    my $org_reg   = PnwQuizzing::Model::Entry->org_registrations;
    my $user_reg  = PnwQuizzing::Model::Entry->user_registrations;

    unless ( $self->req->url->path->trailing_slash(0)->to_string =~ /\.(\w+)$/ and lc($1) eq 'csv' ) {
        $self->stash(
            next_meet => $next_meet,
            org_reg   => $org_reg,
            user_reg  => $user_reg,

            org_reg_sort_by_created => [ sort { $b->{created} cmp $a->{created} } @$org_reg ],
        );
    }
    else {
        $self->app->types->type( 'csv' => [ qw( text/csv application/csv ) ] );

        csv( out => \my $csv, in => [
            map {
                splice( @$_, 12, 1 ) if ( not $next_meet->{house} );
                splice( @$_,  9, 1 ) if ( not $next_meet->{lunch} );
                splice( @$_,  8, 1 ) if ( not $next_meet->{house} );
                $_;
            }
            [ qw( Org. Team Bib Name Captain M/F Grade Rookie House Lunch Notes Role(s) Drive Email ) ],
            (
                map {
                    [ @$_{ qw( org team bib name captain m_f grade rookie house lunch notes email ) } ];
                }
                map {
                    my $org      = $_;
                    my $team_int = 0;

                    map {
                        my $team = $_;
                        my $bib  = 0;

                        $team_int++;

                        grep { $_->{attend} }
                        map {
                            my $quizzer = $_;

                            $quizzer->{org}  = $org->{acronym};
                            $quizzer->{team} = $org->{acronym} . ' ' . $team_int;
                            $quizzer->{bib}  = ++$bib;

                            $quizzer->{$_} = ( $quizzer->{$_} ) ? 'Yes' : 'No'
                                for ( qw( rookie house lunch ) );

                            $quizzer;
                        } @$team;
                    } @{ $org->{registration} }
                } @$org_reg
            ),
            (
                grep { defined }
                map {
                    my $person = $_;
                    ( ( $person->{registration}{attend} ) ? [
                        $person->{acronym},
                        '',
                        '',
                        $person->{first_name} . ' ' . $person->{last_name},
                        '',
                        '',
                        '',
                        '',
                        ( ( $person->{registration}{house} ) ? 'Yes' : 'No' ),
                        ( ( $person->{registration}{lunch} ) ? 'Yes' : 'No' ),
                        $person->{registration}{notes},
                        join( ', ', @{ $person->{registration}{roles} } ),
                        ( ( $person->{registration}{drive} ) ? 'Yes' : 'No' ),
                        lc( $person->{email} ),
                    ] : undef ),
                    map {
                        my $nonquizzer = $_;
                        [
                            $person->{acronym},
                            '',
                            '',
                            $nonquizzer->{name},
                            '',
                            '',
                            '',
                            '',
                            ( ( $nonquizzer->{house} ) ? 'Yes' : 'No' ),
                            ( ( $nonquizzer->{lunch} ) ? 'Yes' : 'No' ),
                            $nonquizzer->{notes},
                            '',
                            '',
                            '',
                        ]
                    } $person->{registration}{nonquizzers}->@*;
                } @$user_reg
            ),
        ] );

        $self->render( text => $csv );
    }
}

1;

=head1 NAME

PnwQuizzing::Control::Tool

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "tool" actions.

=head1 METHODS

=head2 search

Handler for web content search.

=head2 search

Handler for "search" calls.

=head2 register

Handler for "register" calls.

=head2 register_save

Handler for "register_save" calls.

=head2 meet_data

Handler for "meet_data" calls.

=head1 INHERITANCE

L<Mojolicious::Controller>.
