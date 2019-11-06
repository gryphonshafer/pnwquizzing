#!/usr/bin/env perl
# TODO: delete this file

use lib qw(
    /home/gryphon/cpan/exact/lib
    /home/gryphon/cpan/exact-class/lib
    /home/gryphon/pnwquizzing/lib
);

#-------------------------------------------------------------------------------

# use PnwQuizzing::Model::Email;

# PnwQuizzing::Model::Email->new( type => 'verify_email' )->send({
#     to   => 'Gryphon Shafer <g@shfr.us>',
#     data => {
#         username   => 'EXAMPLE username',
#         first_name => 'EXAMPLE first_name',
#         last_name  => 'EXAMPLE last_name',
#         email      => 'EXAMPLE email',
#         url        => 'http://example.com',
#     },
# });

#-------------------------------------------------------------------------------

# use PnwQuizzing::Model::Register;
# my $meet = PnwQuizzing::Model::Register->new->next_meet;

#-------------------------------------------------------------------------------

use PnwQuizzing::Model::User;

my $user = PnwQuizzing::Model::User->new;
my $name = time;

$user->create({
    username   => $name,
    passwd     => $name,
    first_name => $name,
    last_name  => $name,
    email      => $name . '@example.com',
    church     => 'PNWTI',
});
