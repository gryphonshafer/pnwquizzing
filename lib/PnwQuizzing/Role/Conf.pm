package PnwQuizzing::Role::Conf;

use exact -role, -conf;

class_has conf => sub { Config::App->new };

1;
