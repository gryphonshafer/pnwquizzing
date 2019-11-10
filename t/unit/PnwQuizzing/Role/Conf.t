use Test::Most;
use exact;

package PnwQuizzing {
    use exact -class;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Conf') }, q{new->with_roles('+Conf')} );

ok( $obj->does('PnwQuizzing::Role::Conf'), 'does Conf role' );
ok( $obj->can('conf'), 'can conf()' );
is( ref $obj->conf, 'Config::App', 'conf() is a Config::App' );

ok( $obj->conf($_), "conf exits for: $_" ) for ( qw(
    base_url
    logging
    template
    database
    mojolicious
    bcrypt
    email
) );

done_testing();
