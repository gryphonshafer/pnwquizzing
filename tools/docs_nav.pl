#!/usr/bin/env perl
use exact -cli, -conf;
use PnwQuizzing;

my $pnw      = PnwQuizzing->new;
my $docs_nav = $pnw->with_roles('+DocsNav')->generate_docs_nav;

$pnw->info($docs_nav);

=head1 NAME

docs_nav.pl - Print the "docs nav" data structure

=head1 SYNOPSIS

    docs_nav.pl
        -h|help
        -m|man

=head1 DESCRIPTION

This program will print the data structure of the "docs nav" or DocsNav role's
C<generate_docs_nav()> method.
