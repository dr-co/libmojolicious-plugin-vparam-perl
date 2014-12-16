#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 36;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'DateTime';
    use_ok 'DateTime::Format::DateParse';
    use_ok 'POSIX', qw(strftime);
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'date';
{
    $t->app->routes->post("/test/date/vparam")->to( cb => sub {
        my ($self) = @_;

        my $now = DateTime->now;

        is $self->vparam( date0 => 'date' ), undef,        'date0 undef';
        is $self->vparam( date1 => 'date' ), '2012-02-29', 'date1 rus';
        is $self->vparam( date2 => 'date' ), '2012-02-29', 'date2 eng';
        is $self->vparam( date3 => 'date' ), '2012-02-29', 'date3 rus';
        is $self->vparam( date4 => 'date' ), '2012-02-29', 'date4 eng';

        my $default = DateTime->new(
            year        => $now->year,
            month       => $now->month,
            day         => $now->day,
            time_zone   => 'local',
        )->strftime('%F');
        is $self->vparam( date5 => 'date' ), "$default",    'time => date5';
        is $self->vparam( date6 => 'date' ), '2012-02-29',  'date6 rus';
        is $self->vparam( date7 => 'date' ), '2012-03-02',  'date7 rus';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/date/vparam", form => {
        date0   => undef,
        date1   => '29.02.2012',
        date2   => '2012-02-29',
        date3   => '29.02.2012 11:33:44',
        date4   => '2012-02-29 11:33:44',
        date5   => '11:33:44',
        date6   => '   29.02.2012  ',
        date7   => '2.3.2012 11:33',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'time';
{
    $t->app->routes->post("/test/time/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( time0 => 'time' ), undef,      'time0 undef';
        is $self->vparam( time1 => 'time' ), '00:00:00', 'time1 rus';
        is $self->vparam( time2 => 'time' ), '00:00:00', 'time2 eng';
        is $self->vparam( time3 => 'time' ), '11:33:44', 'time3 rus';
        is $self->vparam( time4 => 'time' ), '11:33:44', 'time4 eng';
        is $self->vparam( time5 => 'time' ), '11:33:44', 'time5';
        is $self->vparam( time6 => 'time' ), '11:33:44', 'time6';
        is $self->vparam( time7 => 'time' ), '11:33:00', 'time7 rus';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/time/vparam", form => {
        time0   => undef,
        time1   => '29.02.2012',
        time2   => '2012-02-29',
        time3   => '29.02.2012 11:33:44',
        time4   => '2012-02-29 11:33:44',
        time5   => '11:33:44',
        time6   => '  11:33:44 ',
        time7   => '2.3.2012 11:33',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'datetime';
{
    $t->app->routes->post("/test/datetime/vparam")->to( cb => sub {
        my ($self) = @_;

        my $now = DateTime->now;
        my $tz  = strftime '%z', localtime;

        is $self->vparam( datetime0 => 'datetime' ), undef,
            'datetime0 undef';

        my $datetime1 = DateTime->new(
            year        => 2012,
            month       => 02,
            day         => 29,
            time_zone   => $tz,
        )->strftime('%F %T %z');
        is $self->vparam( datetime1 => 'datetime' ), "$datetime1",
            'datetime1 rus';
        is $self->vparam( datetime2 => 'datetime' ), "$datetime1",
            'datetime2 eng';

        my $datetime3 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => $tz
        )->strftime('%F %T %z');
        is $self->vparam( datetime3 => 'datetime' ), "$datetime3",
            'datetime3 rus';
        is $self->vparam( datetime4 => 'datetime' ), "$datetime3",
            'datetime4 eng';
        is $self->vparam( datetime5 => 'datetime' ), "$datetime3",
            'datetime5 eng';

        my $datetime6 = DateTime->new(
            year        => $now->year,
            month       => $now->month,
            day         => $now->day,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => $tz,
        )->strftime('%F %T %z');
        is $self->vparam( datetime6 => 'datetime' ), "$datetime6",
            'time => datetime6';

        my $datetime7 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => '+0300'
        )->strftime('%F %T %z');
        is $self->vparam( datetime7 => 'datetime' ), "$datetime7",
            'datetime7 rus';
        is $self->vparam( datetime8 => 'datetime' ), "$datetime7",
            'datetime8 eng';

        my $datetime9 = DateTime->new(
            year        => 2013,
            month       => 3,
            day         => 27,
            hour        => 14,
            minute      => 55,
            second      => 00,
            time_zone   => '+0300'
        )->strftime('%F %T %z');
        is $self->vparam( datetime9 => 'datetime' ), "$datetime9",
            'datetime9 eng from browser';

        my $datetime10 = DateTime->new(
            year        => 2012,
            month       => 3,
            day         => 2,
            hour        => 11,
            minute      => 33,
            second      => 00,
            time_zone   => $tz
        )->strftime('%F %T %z');
        is $self->vparam( datetime10 => 'datetime' ), "$datetime10",
            'datetime10 rus light';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/vparam", form => {
        datetime0   => undef,
        datetime1   => '29.02.2012',
        datetime2   => '2012-02-29',
        datetime3   => '29.02.2012 11:33:44',
        datetime4   => '2012-02-29 11:33:44',
        datetime5   => '   2012-02-29   11:33:44  ',
        datetime6   => '11:33:44',
        datetime7   => '29.02.2012 11:33:44 +0300',
        datetime8   => '2012-02-29 11:33:44 +0300',
        datetime9   => 'Wed Mar 27 2013 15:55:00 GMT+0400 (MSK)',
        datetime10  => '2.3.2012 11:33',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

