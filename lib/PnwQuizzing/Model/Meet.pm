package PnwQuizzing::Model::Meet;

use exact -conf, -class;
use DateTime;

with 'Omniframe::Role::Model';

sub next_meet_id ($self) {
    return $self->dq->sql(q{
        SELECT meet_id
        FROM meet
        WHERE DATETIME(start) >= DATETIME('NOW')
        ORDER BY start
        LIMIT 1
    })->run->value;
}

sub next_meet_data ($self) {
    my $meet = $self->dq->sql(q{
        SELECT
            m.meet_id,
            m.name AS meet_name,
            STRFTIME( '%s', m.start ) AS start,
            m.days,
            m.deadline,
            m.reminder,
            m.house,
            m.lunch,
            o.name AS org_name,
            o.acronym,
            o.address,
            m.org_override,
            m.address_override
        FROM meet AS m
        LEFT JOIN org AS o USING (org_id)
        WHERE DATETIME( m.start ) >= DATETIME('NOW')
        ORDER BY m.start
        LIMIT 1
    })->run->first({});

    if ($meet) {
        my $time_zone = conf->get('time_zone');

        $meet->{start_datetime} = DateTime->from_epoch(
            epoch     => $meet->{start},
            time_zone => $time_zone,
        )->strftime('%a, %b %e, %Y at %l:%M %p');

        my $deadline = DateTime->from_epoch(
            epoch     => $meet->{start},
            time_zone => $time_zone,
        )->subtract( days => $meet->{deadline} );

        $deadline = DateTime->new(
            year      => $deadline->year,
            month     => $deadline->month,
            day       => $deadline->day,
            hour      => 9,
            minute    => 0,
            second    => 0,
            time_zone => $time_zone,
        );

        $meet->{past_deadline}     = ( $deadline->epoch < time ) ? 1 : 0;
        $meet->{deadline_datetime} = $deadline->strftime('%a, %b %e, %Y at %l:%M %p');
        $meet->{reminder_day}      = (
            DateTime->now( time_zone => $time_zone )->ymd eq
            DateTime->from_epoch(
                epoch     => $meet->{start},
                time_zone => $time_zone,
            )->subtract( days => $meet->{deadline} + $meet->{reminder} )->ymd
        ) ? 1 : 0;
    }

    return $meet;
}

1;

=head1 NAME

PnwQuizzing::Model::Meet

=head1 DESCRIPTION

This model provides functionality for meet objects.

=head1 METHODS

=head2 next_meet_id

Return the next (via scheduled start time) meet database row ID.

=head2 next_meet_data

Return the next (via scheduled start time) meet row data.
