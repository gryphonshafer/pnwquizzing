package PnwQuizzing::Role::Template;

use exact -role;
use Template;

with 'PnwQuizzing::Role::Conf';

class_has version => time;

my $tt;
sub tt ( $self, $type = 'web' ) {
    unless ( $tt->{$type} ) {
        my $settings = $self->tt_settings($type);
        $tt->{$type} = Template->new( $settings->{config} );
        $settings->{context}->( $tt->{$type}->context );
    }
    return $tt->{$type};
}

sub tt_settings ( $self, $type = 'web' ) {
    my $tt_conf = $self->conf->get('template');

    return {
        config => {
            COMPILE_EXT  => $tt_conf->{compile_ext},
            COMPILE_DIR  => $self->conf->get( 'config_app', 'root_dir' ) . '/' . $tt_conf->{compile_dir},
            WRAPPER      => $tt_conf->{$type}{wrapper},
            INCLUDE_PATH => [
                map {
                    $self->conf->get( 'config_app', 'root_dir' ) . '/' . $_
                } @{ $tt_conf->{$type}{include_path} }
            ],
            FILTERS => {
                ucfirst => sub { return ucfirst shift },
                round   => sub { return int( $_[0] + 0.5 ) },
            },
            ENCODING  => 'utf8',
            CONSTANTS => {
                version => $self->version,
            },
            VARIABLES => {
                time => sub { return time },
                rand => sub { return int( rand( $_[0] // 2 ) + ( $_[1] // 0 ) ) },
                pick => sub { return ( map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ rand, $_ ] } @_ )[0] },
            },
        },
        context => sub ($context) {
            $context->define_vmethod( 'scalar', 'lower',   sub { return lc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'upper',   sub { return uc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'ucfirst', sub { return ucfirst( lc( $_[0] ) ) } );

            $context->define_vmethod( $_, 'ref', sub { return ref( $_[0] ) } ) for ( qw( scalar list hash ) );

            $context->define_vmethod( 'scalar', 'commify', sub {
                return scalar( reverse join( ',', unpack( '(A3)*', scalar( reverse $_[0] ) ) ) );
            } );
        },
    };
}

1;
