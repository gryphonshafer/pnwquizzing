#!/usr/bin/env perl
use exact -cli, -conf;
use PnwQuizzing::Model::Email;
use PnwQuizzing::Model::User;
use PnwQuizzing::Model::Meet;
use PnwQuizzing::Model::Entry;

my $settings  = options( qw( user|u=s email|e=s force|f ) );
my $next_meet = PnwQuizzing::Model::Meet->next_meet_data;
my $email     = PnwQuizzing::Model::Email->new( type => 'registration_reminder' );

$email->log_level('warning');

if ( $next_meet->{reminder_day} or $settings->{force} ) {
    ( my $from_email = conf->get( qw( email from ) ) ) =~ s/^[^<]*<([^>]+)>.*$/$1/;

    for my $user ( @{ PnwQuizzing::Model::User->new->every({ dormant => 0 }) } ) {
        next if ( grep { $_ and $_ eq 'Quizzer' } @{ $user->data->{roles} } );
        next if ( $settings->{user} and $user->data->{username} ne $settings->{user} );

        $email->send({
            to => sprintf(
                '%s %s <%s>',
                ( map { $user->data->{$_} } qw( first_name last_name ) ),
                ( $settings->{email} || $user->data->{email} )
            ),
            data => {
                user       => $user,
                url        => conf->get('base_url'),
                next_meet  => $next_meet,
                from_email => $from_email,
                user_reg   => PnwQuizzing::Model::Entry->user_registrations( $user->id ),
                org_reg    => (
                    ( $user->data->{org_id} )
                        ? PnwQuizzing::Model::Entry->org_registrations( $user->data->{org_id} )
                        : [],
                ),
            },
        });
    }
}

=head1 NAME

registration_reminder.pl - Send registration reminder emails to coaches

=head1 SYNOPSIS

    registration_reminder.pl OPTIONS
        -u|user  USERNAME  # username to send to (for testing)
        -e|email EMAIL     # override email address (for testing)
        -f|force           # if set, will skip "reminder day" check
        -h|help
        -m|man

=head1 DESCRIPTION

This program will send registration reminder emails to coaches. For any user
account that's active that either has the profile role of "Coach" or has a most
recent meet registration that included a role of "Coach", the user will get an
email generated and sent to them that includes the current registration data.

Should a username (i.e. "user") be provided, only email for that user will be
sent. Should an email be provided, all email will be sent to that address. And
should "force" be applied, the normal check of if the current day is a
"reminder day" is skipped.

Thus, you probably want to run tests with one of the following:

    registration_reminder.pl -f -u YOUR_USERNAME
    registration_reminder.pl -f -e YOUR_EMAIL
