#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 96;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
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

note 'int';
{
    $t->app->routes->post("/test/int/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int' ), 0,         'int0';
        is $self->vparam( int1 => 'int' ), 111,       'int1';
        is $self->vparam( int2 => 'int' ), 222,       'int2';
        is $self->vparam( int3 => 'int' ), 333,       'int3';
        is $self->vparam( int4 => 'int' ), undef,     'int4';
        is $self->vparam( int5 => 'int' ), undef,     'int5';
        is $self->vparam( int6 => 'int' ), 333,       'int6';
        is $self->vparam( int7 => 'int' ), -333,      'int7';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/int/vparam", form => {

        int0    => 0,
        int1    => 111,
        int2    => '222aaa',
        int3    => 'bbb333bbb',
        int4    => 'ccc',
        int5    => undef,
        int6    => ' 333 ',
        int7    => ' -333 ',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'numeric';
{
    $t->app->routes->post("/test/numeric/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( numeric0 => 'numeric' ), 0,         'numeric0';
        is $self->vparam( numeric1 => 'numeric' ), 111.222,   'numeric1';
        is $self->vparam( numeric2 => 'numeric' ), 222,       'numeric2';
        is $self->vparam( numeric3 => 'numeric' ), 333.444,   'numeric3';
        is $self->vparam( numeric4 => 'numeric' ), undef,     'numeric4';
        is $self->vparam( numeric5 => 'numeric' ), undef,     'numeric5';
        is $self->vparam( numeric6 => 'numeric' ), 333,       'numeric6';
        is $self->vparam( numeric7 => 'numeric' ), -333.444,  'numeric7';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/numeric/vparam", form => {

        numeric0    => 0,
        numeric1    => 111.222,
        numeric2    => '222aaa',
        numeric3    => 'bbb333.444bbb',
        numeric4    => 'ccc',
        numeric5    => undef,
        numeric6    => ' 333. ',
        numeric7    => ' -333.444 ',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'str';
{
    $t->app->routes->post("/test/str/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str0 => 'str' ), '',                    'str0';
        is $self->vparam( str1 => 'str' ), 'aaa111bbb222 ccc333', 'str1';
        is $self->vparam( str2 => 'str' ), '',                    'str2';
        is $self->vparam( str3 => 'str' ), '   ',                 'str3';
        is $self->vparam( str_utf8 => 'str' ), 'абвгд',           'str_utf8';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/str/vparam", form => {
        str0    => undef,
        str1    => 'aaa111bbb222 ccc333',
        str2    => '',
        str3    => '   ',

        str_utf8 => 'абвгд',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

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

        is $self->vparam( datetime0 => 'datetime' ), undef,
            'datetime0 undef';

        my $datetime1 = DateTime->new(
            year        => 2012,
            month       => 02,
            day         => 29,
            time_zone   => 'local'
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
            time_zone   => 'local'
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
            time_zone   => 'local',
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
            hour        => 15,
            minute      => 55,
            second      => 00,
            time_zone   => '+0400'
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
            time_zone   => 'local'
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

note 'bool';
{
    $t->app->routes->post("/test/bool/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( bool1 => 'bool' ), 1,         'bool1 = 1';
        is $self->vparam( bool2 => 'bool' ), 1,         'bool2 = True';
        is $self->vparam( bool3 => 'bool' ), 1,         'bool3 = yes';
        is $self->vparam( bool4 => 'bool' ), 0,         'bool4 = 0';
        is $self->vparam( bool5 => 'bool' ), 0,         'bool5 = faLse';
        is $self->vparam( bool6 => 'bool' ), 0,         'bool6 = no';
        is $self->vparam( bool7 => 'bool' ), 0,         'bool7 = ""';
        is $self->vparam( bool8 => 'bool' ), 0,         'bool8 = undef';
        is $self->vparam( bool9 => 'bool' ), 1,         'bool9 = True';

        is $self->vparam( unknown => {type => 'bool', default => 1}), 1,
                                            'undefined unknown = 1 by default';
        is $self->vparam( unknown => 'bool' ), undef,  'undefined unknown';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/bool/vparam", form => {
        bool1       => '1',
        bool2       => 'True',
        bool3       => 'yes',
        bool4       => '0',
        bool5       => 'faLse',
        bool6       => 'no',
        bool7       => '',
        bool8       => undef,
        bool9       => '  True  ',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'email';
{
    $t->app->routes->post("/test/email/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( email0 => 'email' ), undef,       'email0 undef';
        is $self->vparam( email1 => 'email' ), undef,       'email1 = ""';
        is $self->vparam( email2 => 'email' ), undef,       'email2 = "aaa"';
        is $self->vparam( email3 => 'email' ),'a@b.ru',     'email3 = "a@b.ru"';
        is $self->vparam( email4 => 'email' ),'a@b.ru',     'email4 = "a@b.ru"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/email/vparam", form => {
        email0      => undef,
        email1      => '',
        email2      => 'aaa',
        email3      => 'a@b.ru',
        email4      => '  a@b.ru  ',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'url';
{
    $t->app->routes->post("/test/url/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( url0 => 'url' ), undef,       'url0 undef';
        is $self->vparam( url1 => 'url' ), undef,       'url1 = ""';
        is $self->vparam( url2 => 'url' ), undef,       'url2 = "http://"';
        is $self->vparam( url3 => 'url' ), 'http://a.ru',
            'url3 = "http://a.ru"';
        is $self->vparam( url4 => 'url' ), 'https://a.ru',
            'url4 = "https://a.ru"';
        is $self->vparam( url5 => 'url' ), 'http://aA-bB.Cc.ru?b=1',
            'url5 = "http://aA-bB.Cc.ru?b=1"';
        is $self->vparam( url6 => 'url' ), 'http://a.ru?b=1',
            'url6 = "http://aA-bB.Cc.ru?b=1"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/url/vparam", form => {
        url0        => undef,
        url1        => '',
        url2        => 'http://',
        url3        => 'http://a.ru',
        url4        => 'https://a.ru',
        url5        => 'http://aA-bB.Cc.ru?b=1',
        url6        => '  http://a.ru?b=1  ',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'phone';
{
    $t->app->routes->post("/test/phone/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( phone1 => 'phone' ), '+71234567890',
            'phone1 = +71234567890';
        is $self->vparam( phone2 => 'phone' ), '+71234567890',
            'phone2 = 71234567890';
        is $self->vparam( phone3 => 'phone' ), '+74954567890',
            'phone3 = 4567890';
        is $self->vparam( phone4 => 'phone' ), undef, 'phone4 = ""';
        is $self->vparam( phone5 => 'phone' ), undef, 'phone5 = undef';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/phone/vparam", form => {
        phone1      => '+71234567890',
        phone2      => '71234567890',
        phone3      => '4567890',
        phone4      => '',
        phone5      => undef,
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address';
{
    $t->app->routes->post("/test/address/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( address1 => 'address' ),
            ['United States, New York', -75.610703, 42.93709],
                'address1';
        is $self->vparam( address2 => 'address' ), undef,
            'address2';
        is $self->vparam( address3 => 'address' ), undef,
            'address3';
        is $self->vparam( address4 => 'address' ), undef,
            'address4';
        is $self->vparam( address5 => 'address' ), undef,
            'address5';
        is $self->vparam( address6 => 'address' ), undef,
            'address6';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/vparam", form => {
        address1    => '  United States, New York : -75.610703 ,  42.93709  ',
        address2    => '',
        address3    => undef,
        address4    => '  United States, New York : -75.610703 , ',
        address5    => '-75.610703 ,  42.93709  ',
        address6    => '  : -75.610703 ,  42.93709  ',
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

