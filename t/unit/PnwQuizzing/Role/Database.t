use Test::Most;
use exact;

package PnwQuizzing {
    use exact -class;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Database') }, q{new->with_roles('+Database')} );
ok( $obj->does("PnwQuizzing::Role::$_"), "does $_ role" ) for ( qw( Conf Database ) );
can_ok( $obj, 'dq' );
is( ref $obj->dq, 'DBIx::Query::db', 'dq() is a DBIx::Query' );

my $sqlite_master_count;
lives_ok(
    sub { $sqlite_master_count = $obj->dq->sql('SELECT COUNT(*) FROM sqlite_master')->run->value },
    'database objects query',
);
ok( $sqlite_master_count > 0, 'database objects exist' );

done_testing();
