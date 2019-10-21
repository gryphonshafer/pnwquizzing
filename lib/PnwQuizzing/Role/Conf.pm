package PnwQuizzing::Role::Conf;

# use exact -role, -conf;
use Mojo::Base -role, -signatures;
use Config::App;

has conf => sub { Config::App->new };

1;
