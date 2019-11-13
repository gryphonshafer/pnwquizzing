use Test::Most;
use exact;

use_ok('PnwQuizzing::Control::Main');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Control::Main->new }, 'new()' );
isa_ok( $obj, $_ ) for ( 'Mojolicious::Controller', 'PnwQuizzing' );
ok( $obj->does('PnwQuizzing::Role::Secret'), 'does Secret role' );
can_ok( $obj, qw( home_page content git_push ) );

done_testing();
