use Test::Most;
use exact;

use_ok('PnwQuizzing::Control::Tool');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Control::Tool->new }, 'new()' );
isa_ok( $obj, $_ ) for ( 'Mojolicious::Controller', 'PnwQuizzing' );
ok( $obj->does('PnwQuizzing::Role::Secret'), 'does Secret role' );
can_ok( $obj, qw(
    registration
    hash
    search
    email
    register
    register_data
    register_save
    registration_list
) );

done_testing();
