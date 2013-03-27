#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 112;
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

note 'Simple type syntax';
{
    $t->app->routes->post("/test/1/vparam")->to( cb => sub {
        my ($self) = @_;

        my $now = DateTime->now;

        is $self->vparam( int0 => 'int' ), 0,         'int0 = 0';
        is $self->vparam( int1 => 'int' ), 111,       'int1 = 111';
        is $self->vparam( int2 => 'int' ), 222,       'int2 = 222';
        is $self->vparam( int3 => 'int' ), 333,       'int3 = 333';
        is $self->vparam( int4 => 'int' ), undef,     'int4 = undef';
        is $self->vparam( int5 => 'int' ), undef,     'int5 = undef';
        is $self->vparam( int6 => 'int' ), 333,       'int6 = 333';

        is $self->vparam( str0 => 'str' ), '',                    'str0 = undef';
        is $self->vparam( str1 => 'str' ), 'aaa111bbb222 ccc333', 'str1 = "..."';
        is $self->vparam( str2 => 'str' ), '',                    'str2 = ""';
        is $self->vparam( str3 => 'str' ), '   ',                 'str3 = "   "';

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
        is $self->vparam( date5 => 'date' ), "$default", 'time => date5';
        is $self->vparam( date6 => 'date' ), '2012-02-29', 'date6 rus';

        is $self->vparam( time0 => 'time' ), undef,      'time0 undef';
        is $self->vparam( time1 => 'time' ), '00:00:00', 'time1 rus';
        is $self->vparam( time2 => 'time' ), '00:00:00', 'time2 eng';
        is $self->vparam( time3 => 'time' ), '11:33:44', 'time3 rus';
        is $self->vparam( time4 => 'time' ), '11:33:44', 'time4 eng';
        is $self->vparam( time5 => 'time' ), '11:33:44', 'time5';
        is $self->vparam( time6 => 'time' ), '11:33:44', 'time6';

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

        is $self->vparam( bool1 => 'bool' ), 1,       'bool1 = 1';
        is $self->vparam( bool2 => 'bool' ), 1,       'bool2 = True';
        is $self->vparam( bool3 => 'bool' ), 1,       'bool3 = yes';
        is $self->vparam( bool4 => 'bool' ), 0,       'bool4 = 0';
        is $self->vparam( bool5 => 'bool' ), 0,       'bool5 = faLse';
        is $self->vparam( bool6 => 'bool' ), 0,       'bool6 = no';
        is $self->vparam( bool7 => 'bool' ), 0,       'bool7 = ""';
        is $self->vparam( bool8 => 'bool' ), 0,       'bool8 = undef';
        is $self->vparam( bool9998 => {type => 'bool', default => 1}), 1,
                                            'undefined bool9998 = 1 by default';
        is $self->vparam( bool9999 => 'bool' ), undef,  'undefined bool9999';
        is $self->vparam( bool9 => 'bool' ), 1,         'bool9 = True';

        is $self->vparam( email0 => 'email' ), undef,       'email0 undef';
        is $self->vparam( email1 => 'email' ), undef,       'email1 = ""';
        is $self->vparam( email2 => 'email' ), undef,       'email2 = "aaa"';
        is $self->vparam( email3 => 'email' ),'a@b.ru',     'email3 = "a@b.ru"';
        is $self->vparam( email4 => 'email' ),'a@b.ru',     'email4 = "a@b.ru"';

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

        is_deeply $self->vparam( array1 => 'int' ), [1,2,3], 'array1 = [1,2,3]';

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

    $t->post_ok("/test/1/vparam", form => {

        int0    => 0,
        int1    => 111,
        int2    => '222aaa',
        int3    => 'bbb333bbb',
        int4    => 'ccc',
        int5    => undef,
        int6    => ' 333 ',

        str0    => undef,
        str1    => 'aaa111bbb222 ccc333',
        str2    => '',
        str3    => '   ',

        date0   => undef,
        date1   => '29.02.2012',
        date2   => '2012-02-29',
        date3   => '29.02.2012 11:33:44',
        date4   => '2012-02-29 11:33:44',
        date5   => '11:33:44',
        date6   => '   29.02.2012  ',

        time0   => undef,
        time1   => '29.02.2012',
        time2   => '2012-02-29',
        time3   => '29.02.2012 11:33:44',
        time4   => '2012-02-29 11:33:44',
        time5   => '11:33:44',
        time6   => '  11:33:44 ',

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

        bool1       => '1',
        bool2       => 'True',
        bool3       => 'yes',
        bool4       => '0',
        bool5       => 'faLse',
        bool6       => 'no',
        bool7       => '',
        bool8       => undef,
        bool9       => '  True  ',

        email0      => undef,
        email1      => '',
        email2      => 'aaa',
        email3      => 'a@b.ru',
        email4      => '  a@b.ru  ',

        url0        => undef,
        url1        => '',
        url2        => 'http://',
        url3        => 'http://a.ru',
        url4        => 'https://a.ru',
        url5        => 'http://aA-bB.Cc.ru?b=1',
        url6        => '  http://a.ru?b=1  ',

        array1      => [1, 2, 3],

        phone1      => '+71234567890',
        phone2      => '71234567890',
        phone3      => '4567890',
        phone4      => '',
        phone5      => undef,

    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'regexp';
{
    $t->app->routes->post("/test/2/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str3 => qr{^[\w\s]{0,20}$} ), 'aaa111bbb222 ccc333',
            'regexp for str3="..."';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/2/vparam", form => {
        str3    => 'aaa111bbb222 ccc333',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'callback';
{
    $t->app->routes->post("/test/3/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str4 => sub {"bbbfff555"} ) , 'bbbfff555',
            'sub for str4="..."';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/3/vparam", form => {
        str4    => 'aaa111bbb222 ccc333',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'errors';
{
    $t->app->routes->post("/test/4/vparam")->to( cb => sub {
        my ($self) = @_;

        eval { $self->vparam( int5 => 'non_exiting_type') };
        ok $@, 'type not found';

        # Проверка на неправильные параметры
        is $self->vparam( int5 => {type => 'int', default => '222'} ), 222,
            'default for int5 = 222';
        is $self->verrors, 1, 'One bug';
        my %errors = $self->verrors;
        ok $errors{int5},                 'error int5';
        is $errors{int5}{orig}, 'ddd',   'error int5 orig';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/4/vparam", form => {
        int5    => 'ddd',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'complex syntax';
{
    $t->app->routes->post("/test/4.1/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int1 => 'int' ), undef,
            'int1 simple = undef';
        is $self->vparam( int1 => {type => 'int'} ), undef,
            'int1 full = undef';

        is $self->vparam( int1 => {type => 'int', default => 100500}), 100500,
            'int1 full = 100500';
        is $self->vparam( int1 => 'int', default => 100500), 100500,
            'int1 complex = 100500';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/4.1/vparam", form => {
        int1    => undef,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vparams';
{
    $t->app->routes->post("/test/5/vparam")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        is $self->vparams(int6 => 'int', str5 => 'str')->{int6}, 555,
            'int6=555';
        is $self->vparams(int6 => 'int', str5 => 'str')->{str5}, 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/5/vparam", form => {
        int6    => 555,
        str5    => 'kkll',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'more vparams';
{
    $t->app->routes->post("/test/6/vparam")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        is $self->vparams(int6 => 'int', str5 => 'str')->{int6}, 555,
            'int6=555';
        is $self->vparams(int6 => 'int', str5 => 'str')->{str5}, 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/6/vparam", form => {
        int6    => 555,
        str5    => 'kkll',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort default values';
{
    $t->app->routes->post("/test/7/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vsort()->{page}, 1,                'page = 1';
        is $self->vsort()->{oby}, 1,                 'oby = 1';
        is $self->vsort()->{ods}, 'ASC',             'ods = ASC';
        is $self->vsort()->{rws}, 25,                'rws = 25';

        is $self->vsort(-sort => ['col1', 'col2'])->{oby}, 'col1',
            'oby = "col1"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/7/vparam", form => {})-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort not default values';
{
    $t->app->routes->post("/test/8/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vsort()->{page}, 2,       'page = 2';
        is $self->vsort()->{oby}, '4',      'oby = 4';
        is $self->vsort()->{ods}, 'DESC',   'ods = DESC';
        is $self->vsort()->{rws}, 53,       'rws = 53';

        is $self->vsort(
            -sort => ['col1', 'col2', 'col3', 'col4']
        )->{oby}, 'col4', 'oby="col4"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/8/vparam", form => {
        page    => 2,
        oby     => 3,
        ods     => 'desc',
        rws     => 53,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

