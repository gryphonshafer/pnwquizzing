package PnwQuizzing::Control::Tool;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use File::Find 'find';
use Role::Tiny::With;
use Mojo::File;
use Email::Mailer;
use Text::MultiMarkdown 'markdown';
use Mojo::JSON 'decode_json';
use PnwQuizzing::Model::Register;

with 'PnwQuizzing::Role::Secret';

has registration => sub { PnwQuizzing::Model::Register->new };

sub hash ($self) {
    my $action = $self->param('action') || '';

    $self->stash(
        payload =>
        (
            ( $action eq 'secret' ) ?
                join( "\n", map { $self->secret($_) } split( /\r?\n/, $self->param('payload') ) ) :
            ( $action eq 'transcode' ) ? $self->transcode( $self->param('payload') ) :
            ( $action eq 'translate' ) ? $self->translate( $self->param('payload') ) : ''
        )
    );
}

sub search ($self) {
    my $docs_dir = $self->conf->get( qw( config_app root_dir ) ) . '/docs';

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
                my $content = Mojo::File->new($_)->slurp;
                $content =~ /$for/msi;
            } @files
        ],
    );
}

sub email ($self) {
    if ( $self->param('form_submit') ) {
        my $send_to_self = $self->param('send_to_self');
        my $roles        = $self->every_param('role');

        if ( not $send_to_self and not @$roles ) {
            $self->stash(
                message => 'No recipient targets selected. Select at least one target and resubmit.',
            );
        }
        elsif ( not $self->param('subject') ) {
            $self->stash(
                message => 'No subject provided. Enter an email subject and resubmit.',
            );
        }
        elsif ( not $self->param('payload') ) {
            $self->stash(
                message => 'No email content to send. Enter email content and resubmit.',
            );
        }
        else {
            my $to   = $self->stash('user')->roles_to_emails($roles);
            my $from = sprintf(
                '%s %s <%s>',
                @{ $self->stash('user')->data }{ qw( first_name last_name email ) },
            );
            push( @$to, $from ) if ( $send_to_self and not grep { $_ eq $from } @$to );

            Email::Mailer->new(
                from    => $from,
                to      => $to,
                subject => $self->param('subject'),
                html    => markdown( $self->param('payload') ),
            )->send;

            $self->stash(
                message => {
                    type => 'success',
                    text => 'Successfully sent email to target list.',
                }
            );
        }
    }

    $self->stash(
        roles   => $self->stash('user')->roles,
        payload => $self->param('payload'),
        subject => $self->param('subject'),
    );
}

sub register ($self) {
    my $next_meet = $self->stash('next_meet') || $self->registration->next_meet( $self->stash('user') );
    $self->stash(%$next_meet);
}

sub register_data ($self) {
    $self->render( json => {
        church => $self->stash('user')->church,
        roles  => $self->stash('user')->roles,
        %{ $self->registration->persons( $self->stash('user') ) },
    } );
}

sub register_save ($self) {
    if ( $self->param('data') ) {
        my $next_meet = $self->registration->save_registration(
            decode_json( $self->param('data') ),
            $self->stash('user'),
        );

        $self->flash(
            next_meet => $next_meet,
            message   => {
                type => 'success',
                text => 'Successfully saved quiz meet registration data.',
            }
        ) if ($next_meet);
    }

    return $self->redirect_to('/tool/register');
}

sub registration_list ($self) {
    $self->stash( %{ $self->registration->current_data( $self->stash('user') ) } );
}

1;
