#!/usr/bin/env perl
use exact -cli, -conf;
use PnwQuizzing::Model::Email;
use PnwQuizzing::Model::User;
use PnwQuizzing::Model::Meet;
use PnwQuizzing::Model::Entry;

podhelp;

my $next_meet = PnwQuizzing::Model::Meet->next_meet_data;

if ( $next_meet->{reminder_day} ) {
    ( my $from_email = conf->get( qw( email from ) ) ) =~ s/^[^<]*<([^>]+)>.*$/$1/;

    for my $user ( @{ PnwQuizzing::Model::User->new->every({ dormant => 0 }) } ) {
        next if ( grep { $_ eq 'Quizzer' } @{ $user->data->{roles} } );

        PnwQuizzing::Model::Email->new( type => 'registration_reminder' )->send({
            to   => sprintf( '%s %s <%s>', map { $user->data->{$_} } qw( first_name last_name email ) ),
            data => {
                user      => $user,
                url       => conf->get('base_url'),
                next_meet => $next_meet,
                user_reg  => PnwQuizzing::Model::Entry->user_registrations(
                    $next_meet->{meet_id},
                    $user->id,
                ),
                org_reg => PnwQuizzing::Model::Entry->org_registrations(
                    $next_meet->{meet_id},
                    $user->data->{org_id},
                ),
                from_email => $from_email,
            },
        });
    }
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
