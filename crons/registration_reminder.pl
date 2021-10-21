#!/usr/bin/env perl
use exact -cli, -conf;
use PnwQuizzing::Model::Email;
use PnwQuizzing::Model::User;
use PnwQuizzing::Model::Meet;
use PnwQuizzing::Model::Entry;

podhelp;

my $next_meet = PnwQuizzing::Model::Meet->next_meet_data;

for my $user ( @{ PnwQuizzing::Model::User->new->every } ) {
    my $user_reg = PnwQuizzing::Model::Entry->user_registrations(
        $next_meet->{meet_id},
        $user->id,
    );

    PnwQuizzing::Model::Email->new( type => 'registration_reminder' )->send({
        to   => sprintf( '%s %s <%s>', map { $user->data->{$_} } qw( first_name last_name email ) ),
        data => {
            user      => $user,
            url       => conf->get('base_url'),
            next_meet => $next_meet,
            user_reg  => $user_reg,
            org_reg   => PnwQuizzing::Model::Entry->org_registrations(
                $next_meet->{meet_id},
                $user->data->{org_id},
            ),
        },
    }) if (
        scalar( grep { $_ eq 'Coach' } @{ $user->data->{roles} || [] } ) or (
            ref $user_reg and
            ref $user_reg->[0] and
            ref $user_reg->[0]{registration} and
            ref $user_reg->[0]{registration}{roles} and
            scalar( grep { $_ eq 'Coach' } @{ $user_reg->[0]{registration}{roles} } )
        )
    );
}

=head1 NAME

registration_reminder.pl - Send registration reminder emails to coaches

=head1 SYNOPSIS

    registration_reminder.pl OPTIONS
        -h|help
        -m|man

=head1 DESCRIPTION

This program will send registration reminder emails to coaches. For any user
account that's active that either has the profile role of "Coach" or has a most
recent meet registration that included a role of "Coach", the user will get an
email generated and sent to them that includes the current registration data.
