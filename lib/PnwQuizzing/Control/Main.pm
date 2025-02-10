package PnwQuizzing::Control::Main;

use exact -conf, 'Mojolicious::Controller';
use Mojo::Asset::File;
use Mojo::File 'path';
use Mojo::Util 'decode';
use Text::MultiMarkdown 'markdown';

sub home_page ($self) {
    my $asset = Mojo::Asset::File->new(
        path => join( '/',
            conf->get( qw( config_app root_dir ) ),
            conf->get( qw( docs dir ) ),
            'index.md',
        ),
    );

    my $payload = decode( 'UTF-8', $asset->slurp );
    my $title   = ( $payload =~ s/^#\s*([^#]+?)\s*$//ms ) ? $1 : '';

    $self->stash( payload => markdown($payload), title => $title );
}

sub content ($self) {
    $self->document(
        conf->get( qw( docs dir ) ) . '/' . $self->stash('name'),
        sub ( $payload, $type ) {
            if ( $type eq 'md' ) {
                $payload =~ s|(\[[^\]]+\]\([^\)]+\.)(\w+)\)|
                    my ( $x, $y, $z ) = map { $_ // '' } $1, $2, $3;

                    my $ft   = lc $y;
                    my $icon =
                        ( $ft eq 'pdf'  ) ? 'file-pdf'   :
                        ( $ft eq 'doc'  ) ? 'file-word'  :
                        ( $ft eq 'docx' ) ? 'file-word'  :
                        ( $ft eq 'xls'  ) ? 'file-excel' :
                        ( $ft eq 'xlsm' ) ? 'file-excel' :
                        ( $ft eq 'xlsb' ) ? 'file-excel' :
                        ( $ft eq 'xlsx' ) ? 'file-excel' : undef;

                    ($icon)
                        ? ( qq{$x$y) <i class="fa-regular fa-} . $icon . q{"></i>} )
                        : "$x$y$z)";
                |eg;

                my $directives;
                $directives->{ lc $1 } = 1 while ( $payload =~ /<!--\s*%\s*(.+?)\s*-->/sg );

                my $header_photo;
                unless ( $directives->{hide_header_photo} ) {
                    my $header_photos = $self->stash('header_photos');
                    $header_photo     = $header_photos->[ rand @$header_photos ];
                }
                $self->stash( header_photo => $header_photo );
            }

            return $payload;
        },
    );

    if ( $self->res->code and $self->res->code == 404 ) {
        $self->stash( 'mojo.finished' => 0 );
        $self->flash( memo => {
            class   => 'error',
            message => 'Unable to find the resource previously requested. Redirected to home page.',
        } );
        $self->redirect_to('/');
    }
}

1;

=head1 NAME

PnwQuizzing::Control::Main

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "main" or general actions, including C<content> to feed documents.

=head1 METHODS

=head2 home_page

Handler for the home page of the web site.

=head2 content

Handler for everything under "/docs" served via the documents feeder.

=head1 INHERITANCE

L<Mojolicious::Controller>.
