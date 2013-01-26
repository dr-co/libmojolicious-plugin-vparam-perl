#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 109;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

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

        ok $self->vparam( int0 => 'int' ) == 0,         'int0 = 0';
        ok $self->vparam( int1 => 'int' ) == 111,       'int1 = 111';
        ok $self->vparam( int2 => 'int' ) == 222,       'int2 = 222';
        ok $self->vparam( int3 => 'int' ) == 333,       'int3 = 333';
        ok !defined $self->vparam( int4 => 'int' ),     'int4 = undef';
        ok !defined $self->vparam( int5 => 'int' ),     'int5 = undef';
        ok $self->vparam( int6 => 'int' ) == 333,       'int6 = 333';

        ok $self->vparam( str0 => 'str' ) eq '',                    'str0 = undef';
        ok $self->vparam( str1 => 'str' ) eq 'aaa111bbb222 ccc333', 'str1 = "..."';
        ok $self->vparam( str2 => 'str' ) eq '',                    'str2 = ""';
        ok $self->vparam( str3 => 'str' ) eq '   ',                 'str3 = "   "';

        ok !defined $self->vparam( date0 => 'date' ),        'date0 undef';
        ok $self->vparam( date1 => 'date' ) eq '2012-02-29', 'date1 rus';
        ok $self->vparam( date2 => 'date' ) eq '2012-02-29', 'date2 eng';
        ok $self->vparam( date3 => 'date' ) eq '2012-02-29', 'date3 rus';
        ok $self->vparam( date4 => 'date' ) eq '2012-02-29', 'date4 eng';

        my $default = DateTime->new( year => DateTime->now->year)->strftime('%F');
        ok $self->vparam( date5 => 'date' ) eq $default, 'time => date5';
        ok $self->vparam( date6 => 'date' ) eq '2012-02-29', 'date6 rus';

        ok !defined $self->vparam( time0 => 'time' ),      'time0 undef';
        ok $self->vparam( time1 => 'time' ) eq '00:00:00', 'time1 rus';
        ok $self->vparam( time2 => 'time' ) eq '00:00:00', 'time2 eng';
        ok $self->vparam( time3 => 'time' ) eq '11:33:44', 'time3 rus';
        ok $self->vparam( time4 => 'time' ) eq '11:33:44', 'time4 eng';
        ok $self->vparam( time5 => 'time' ) eq '11:33:44', 'time5';
        ok $self->vparam( time6 => 'time' ) eq '11:33:44', 'time6';

        ok !defined $self->vparam( datetime0 => 'datetime' ),
            'datetime0 undef';
        ok $self->vparam( datetime1 => 'datetime' ) eq '2012-02-29 00:00:00',
            'datetime1 rus';
        ok $self->vparam( datetime2 => 'datetime' ) eq '2012-02-29 00:00:00',
            'datetime2 eng';
        ok $self->vparam( datetime3 => 'datetime' ) eq '2012-02-29 11:33:44',
            'datetime3 rus';
        ok $self->vparam( datetime4 => 'datetime' ) eq '2012-02-29 11:33:44',
            'datetime4 eng';

        my $default2 = DateTime->new(
            year => DateTime->now->year
        )->strftime('%F 11:33:44');
        ok $self->vparam( datetime5 => 'datetime' ) eq $default2,
            'time => datetime5';
        ok $self->vparam( datetime6 => 'datetime' ) eq '2012-02-29 11:33:44',
            'datetime6 eng';

        ok $self->vparam( bool1 => 'bool' ) == 1,       'bool1 = 1';
        ok $self->vparam( bool2 => 'bool' ) == 1,       'bool2 = True';
        ok $self->vparam( bool3 => 'bool' ) == 1,       'bool3 = yes';
        ok $self->vparam( bool4 => 'bool' ) == 0,       'bool4 = 0';
        ok $self->vparam( bool5 => 'bool' ) == 0,       'bool5 = faLse';
        ok $self->vparam( bool6 => 'bool' ) == 0,       'bool6 = no';
        ok $self->vparam( bool7 => 'bool' ) == 0,       'bool7 = ""';
        ok $self->vparam( bool8 => 'bool' ) == 0,       'bool8 = undef';
        ok $self->vparam( bool9998 => {type => 'bool', default => 1}) == 1,
                                            'undefined bool9998 = 1 by default';
        ok ! defined $self->vparam( bool9999 => 'bool' ), 'undefined bool9999';
        ok $self->vparam( bool9 => 'bool' ) == 1,       'bool9 = True';

        ok !defined $self->vparam( email0 => 'email' ),     'email0 undef';
        ok !defined $self->vparam( email1 => 'email' ),     'email1 = ""';
        ok !defined $self->vparam( email2 => 'email' ),     'email2 = "aaa"';
        ok $self->vparam( email3 => 'email' ) eq 'a@b.ru',  'email3 = "a@b.ru"';
        ok $self->vparam( email4 => 'email' ) eq 'a@b.ru',  'email4 = "a@b.ru"';

        ok !defined $self->vparam( url0 => 'url' ),     'url0 undef';
        ok !defined $self->vparam( url1 => 'url' ),     'url1 = ""';
        ok !defined $self->vparam( url2 => 'url' ),     'url2 = "http://"';
        ok $self->vparam( url3 => 'url' ) eq 'http://a.ru',
            'url3 = "http://a.ru"';
        ok $self->vparam( url4 => 'url' ) eq 'https://a.ru',
            'url4 = "https://a.ru"';
        ok $self->vparam( url5 => 'url' ) eq 'http://aA-bB.Cc.ru?b=1',
            'url5 = "http://aA-bB.Cc.ru?b=1"';
        ok $self->vparam( url6 => 'url' ) eq 'http://a.ru?b=1',
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

    $t->post_form_ok("/test/1/vparam" => {

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
        datetime5   => '11:33:44',
        datetime6   => '   2012-02-29   11:33:44  ',

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

        ok $self->vparam( str3 => qr{^[\w\s]{0,20}$} ) eq 'aaa111bbb222 ccc333',
            'regexp for str3="..."';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/2/vparam" => {
        str3    => 'aaa111bbb222 ccc333',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'callback';
{
    $t->app->routes->post("/test/3/vparam")->to( cb => sub {
        my ($self) = @_;

        ok $self->vparam( str4 => sub {"bbbfff555"} ) eq 'bbbfff555',
            'sub for str4="..."';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/3/vparam" => {
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
        ok $self->vparam( int5 => {type => 'int', default => '222'} ) == 222,
            'default for int5 = 222';
        ok $self->verrors == 1, 'One bug';
        my %errors = $self->verrors;
        ok $errors{int5},                  'error int5';
        ok $errors{int5}{orig} eq 'ddd',   'error int5 orig';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/4/vparam" => {
        int5    => 'ddd',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'complex syntax';
{
    $t->app->routes->post("/test/4.1/vparam")->to( cb => sub {
        my ($self) = @_;

        ok !defined $self->vparam( int1 => 'int' ),
            'int1 simple = undef';
        ok !defined $self->vparam( int1 => {type => 'int'} ),
            'int1 full = undef';

        ok $self->vparam( int1 => {type => 'int', default => 100500}) == 100500,
            'int1 full = 100500';
        ok $self->vparam( int1 => 'int', default => 100500) == 100500,
            'int1 complex = 100500';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/4.1/vparam" => {
        int1    => undef,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vparams';
{
    $t->app->routes->post("/test/5/vparam")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        ok $self->vparams(int6 => 'int', str5 => 'str')->{int6} == 555,
            'int6=555';
        ok $self->vparams(int6 => 'int', str5 => 'str')->{str5} eq 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/5/vparam" => {
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
        ok $self->vparams(int6 => 'int', str5 => 'str')->{int6} == 555,
            'int6=555';
        ok $self->vparams(int6 => 'int', str5 => 'str')->{str5} eq 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/6/vparam" => {
        int6    => 555,
        str5    => 'kkll',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort default values';
{
    $t->app->routes->post("/test/7/vparam")->to( cb => sub {
        my ($self) = @_;

        ok $self->vsort()->{page} == 1,                 'page = 1';
        ok $self->vsort()->{oby}  == 1,                 'oby = 1';
        ok $self->vsort()->{ods}  eq 'ASC',             'ods = ASC';
        ok $self->vsort()->{rws}  == 25,                'rws = 25';

        ok $self->vsort(-sort => ['col1', 'col2'])->{oby} eq 'col1',
            'oby = "col1"';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/7/vparam" => {})-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort not default values';
{
    $t->app->routes->post("/test/8/vparam")->to( cb => sub {
        my ($self) = @_;

        ok $self->vsort()->{page} == 2,      'page = 2';
        ok $self->vsort()->{oby}  eq '4',    'oby = 4';
        ok $self->vsort()->{ods}  eq 'DESC', 'ods = DESC';
        ok $self->vsort()->{rws} == 53,      'rws = 53';

        ok $self->vsort(
            -sort => ['col1', 'col2', 'col3', 'col4']
        )->{oby} eq 'col4', 'oby="col4"';

        $self->render(text => 'OK.');
    });

    $t->post_form_ok("/test/8/vparam" => {
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

