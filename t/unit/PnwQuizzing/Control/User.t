use Test::Most;
use exact;

use_ok('PnwQuizzing::Control::User');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Control::User->new }, 'new()' );
isa_ok( $obj, $_ ) for ( 'Mojolicious::Controller', 'PnwQuizzing' );

can_ok( $obj, qw(
    login
    logout
    account
    verify
    list
    reset_password
) );

done_testing();
