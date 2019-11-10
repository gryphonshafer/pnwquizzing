use Test::Most;
use exact;

package PnwQuizzing {
    use exact -class;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Bcrypt') }, q{new->with_roles('+Bcrypt')} );
ok( $obj->does("PnwQuizzing::Role::$_"), "does $_ role" ) for ( qw( Bcrypt Conf ) );
ok( $obj->can('bcrypt'), 'can bcrypt()' );

my $data = {
    alpha => {
        salt => '91da14caf768cff6',
        in   => 'e2c388ca378a317d422cd1c69558f24684591c1372ec0d',
        out  => '7a09b5bda25104a63edc4e5cb878a8dd445bfd3810d985',
    },
    beta => {
        salt => '91da14caf768cff5',
        in   => 'e2c388ca378a317d422cd1c69558f24684591c1372ec0d',
        out  => '5225fc735a808426a7d4b14f94ce58f1f397e0a928a5aa',
    },
};

my $test = sub ($name) {
    $obj->conf->put( 'bcrypt', 'salt', $data->{$name}{salt} );

    is(
        $obj->bcrypt( $data->{$name}{in} ),
        $data->{$name}{out},
        $name,
    );
};

$test->($_) for ( qw(
    alpha
    alpha
    beta
    beta
    alpha
) );

done_testing();
