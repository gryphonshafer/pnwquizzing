#!/usr/bin/env perl

# TODO: remove lib block
use lib qw(
    /home/gryphon/cpan/exact/lib
    /home/gryphon/cpan/exact-class/lib
);

use MojoX::ConfigAppStart;
MojoX::ConfigAppStart->start;
