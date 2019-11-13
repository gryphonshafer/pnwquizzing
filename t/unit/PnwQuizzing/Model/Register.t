use Test::Most;
use Test::MockModule;
use exact;
use DBIx::Query;

my $all = [];
package MockBlank {
    sub new { return bless( {}, $_[0] ) }
    sub all { return $all }
    sub next { return undef }
    sub AUTOLOAD { return $_[0] }
}
my $dq = Test::MockModule->new('DBIx::Query::st', no_auto => 1 );
$dq->redefine( 'run', sub { return MockBlank->new } );

my $model = Test::MockModule->new('PnwQuizzing::Model');
$model->redefine( 'save', sub { return $_[0] } );
$model->redefine( 'load', sub {
    my ($self) = @_;
    $self->data( { user_id => 1 } );
    return $self;
} );

use_ok('PnwQuizzing::Model::Register');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Model::Register->new }, 'new()' );
isa_ok( $obj, 'PnwQuizzing::Model' );
can_ok( $obj, qw( new next_meet show_notice persons save_registration current_data send_reminders ) );

ok( $obj == PnwQuizzing::Model::Register->new, 'new() returns singleton' );
lives_ok( sub { $obj->next_meet }, 'next_meet()' );

use_ok('PnwQuizzing::Model::User');
my $user;
lives_ok( sub{ $user = PnwQuizzing::Model::User->new->load(1) }, 'create user obj' );
lives_ok( sub { $obj->show_notice( $user, '' ) }, 'show_notice()' );
lives_ok( sub { $obj->persons($user) }, 'persons()' );

done_testing();
