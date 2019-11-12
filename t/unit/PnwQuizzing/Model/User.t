use Test::Most;
use Test::MockModule;
use exact;
use DBIx::Query;

my $all;
package MockBlank {
    sub new { return bless( {}, $_[0] ) }
    sub all { return $all }
    sub AUTOLOAD { return $_[0] }
}
my $dq = Test::MockModule->new('DBIx::Query::st', no_auto => 1 );
$dq->redefine( 'run', sub { return MockBlank->new } );

package PnwQuizzing::Model::Email {
    sub new { return bless( {}, $_[0] ) }
    sub AUTOLOAD { return $_[0] }
}
$INC{'PnwQuizzing/Model/Email.pm'} = 1;

my $model = Test::MockModule->new('PnwQuizzing::Model');
$model->redefine( 'save', sub { return $_[0] } );
$model->redefine( 'load', sub {
    my ($self) = @_;
    $self->data( {
        user_id    => 1,
        passwd     => '12345678901234567890',
        first_name => 'first_name',
        last_name  => 'last_name',
        email      => 'example@example.com',
    } );
    return $self;
} );

use_ok('PnwQuizzing::Model::User');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Model::User->new }, 'new()' );
isa_ok( $obj, 'PnwQuizzing::Model' );
ok( $obj->does('PnwQuizzing::Role::Bcrypt'), 'does Bcrypt role' );
can_ok( $obj, qw(
    name
    create edit roles churches church login passwd verify_email verify
    roles_to_emails all_users_data reset_password_email reset_password
) );

throws_ok(
    sub { $obj->create({}) },
    qr/"username" appears to not be a valid input value/,
    'create() with incomplete params'
);

my $user_data = {
    username   => '__test_pnwquizzing_model_user_' . $$,
    passwd     => 'passwd',
    first_name => 'first_name',
    last_name  => 'last_name',
    email      => 'invalid',
    church     => '_NEW',
};
throws_ok(
    sub { $obj->create( { %$user_data } ) },
    qr/"email" appears to not be a valid input value/,
    'create() with invalid email'
);

$user_data->{email} = 'example@example.com';
lives_ok( sub { $obj = $obj->create( { %$user_data } ) }, 'create() with valid input' );
isa_ok( $obj, 'PnwQuizzing::Model::User' );

$user_data->{email} = 'invalid';
throws_ok(
    sub { $obj->edit( { %$user_data } ) },
    qr/"email" appears to not be a valid input value/,
    'edit() with invalid email'
);

$user_data->{email} = 'example@example.com';
lives_ok( sub { $obj = $obj->edit( { %$user_data } ) }, 'edit() with valid input' );
isa_ok( $obj, 'PnwQuizzing::Model::User' );

$all = [{ name => 'Test' }];
lives_ok( sub { $obj->roles([[]]) }, 'roles()' );

lives_ok( sub { $obj->churches }, 'churches()' );
lives_ok( sub { $obj->church }, 'church()' );
lives_ok( sub { $obj = $obj->login( @$user_data{ qw( username passwd ) } ) }, 'login() with valid input' );
lives_ok( sub { $obj->passwd('new_passwd') }, 'passwd()' );
lives_ok( sub { $obj->verify_email('url') }, 'verify_email()' );
lives_ok( sub { $obj->verify( 1, 'hash' ) }, 'verify()' );

$all = [];
lives_ok( sub { $obj->roles_to_emails([]) }, 'roles_to_emails()' );
lives_ok( sub { $obj->all_users_data }, 'all_users_data()' );
lives_ok( sub { $obj->reset_password_email }, 'reset_password_email()' );
lives_ok( sub { $obj->reset_password( 1, 'passwd' ) }, 'reset_password()' );

done_testing();
