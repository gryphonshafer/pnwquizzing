use Test::Most;
use exact;

package PnwQuizzing {
    use exact -class;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+DocsNav') }, q{new->with_roles('+DocsNav')} );
ok( $obj->does("PnwQuizzing::Role::$_"), "does $_ role" ) for ( qw( Conf DocsNav ) );
can_ok( $obj, 'generate_docs_nav' );

my $docs_nav;
lives_ok( sub { $docs_nav = $obj->generate_docs_nav }, 'generate_docs_nav()' );

ok(
    ( ref $docs_nav eq 'ARRAY' and $docs_nav->[0]{name} eq 'Home Page' and $docs_nav->[0]{href} eq '/' ),
    'basic data structure',
);

done_testing();
