use Test::Most;
use exact;

use_ok('PnwQuizzing::Model');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Model->new }, 'new()' );
isa_ok( $obj, 'exact::class' );
ok( $obj->does("PnwQuizzing::Role::$_"), "does $_ role" ) for ( qw( Conf Database Logging ) );

done_testing();
