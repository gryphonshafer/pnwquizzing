use Test::Most;
use exact;

use_ok('PnwQuizzing::Control');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Control->new }, 'new()' );
isa_ok( $obj, $_ ) for ( 'Mojolicious', 'PnwQuizzing' );
ok( $obj->does("PnwQuizzing::Role::$_"), "does $_ role" ) for ( qw( DocsNav Template ) );
can_ok( $obj, qw(
    startup
    build_css
    setup_mojo_logging
    setup_access_log
    setup_templating
    setup_session_login
) );

done_testing();
