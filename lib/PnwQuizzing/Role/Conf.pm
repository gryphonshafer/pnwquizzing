package PnwQuizzing::Role::Conf;

use exact -role, -conf;

has conf => sub { Config::App->new };

1;
