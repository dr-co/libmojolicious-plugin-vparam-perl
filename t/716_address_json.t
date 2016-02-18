#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 55;
use Encode qw(decode encode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Encode',        qw(encode_utf8);
    use_ok 'JSON::XS',      qw(encode_json);
    use_ok 'Digest::MD5',   qw(md5_hex);
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Mojolicious::Plugin::Vparam::Address';
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

note 'address json';
{
    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt) = (
        'United States, New York : 42.93709 , -75.610703',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        123,
        'p',
        'en',
        'extra',
    );
    my $json = encode_json [ $id, $type, $address, $lon, $lat, $lang, $opt ];

    my $json7 = encode_json [
        $id, $type, $address, $lon, $lat, $lang, 'unknown'
    ];
    my $json8 = encode_json [
        $id, $type, $address, $lon, $lat, $lang, undef
    ];

    my ($address2, $lon2, $lat2) = (
        'United States, Elizabeth',
        40.6622967,
        -74.1965427,
    );
    my $json9 = encode_json [
        $id, $type, $address, $lon, $lat, $lang, [$address2, $lon2, $lat2]
    ];

    $t->app->routes->post("/test/address/json/vparam")->to(cb => sub {
        my ($self) = @_;

        my $a = $self->vparam( address1 => 'address' );

        is_deeply
            $a,
            [$address, $lon, $lat, $md5, $full, $id, $type, $lang, $opt],
            'address1';
        is $a->address,     $address,   'address';
        is $a->lon,         $lon,       'lon';
        is $a->lat,         $lat,       'lat';
        is $a->md5,         $md5,       'md5';
        is $a->fullname,    $full,      'fullname';
        is $a->id,          $id,        'id';
        is $a->type,        $type,      'type';
        is $a->lang,        $lang,      'lang';
        is $a->opt,         $opt,       'opt';
        is $a->is_extra,    1,          'is_extra';
        is $self->verror('address1'), 0, 'address1 no error';

        is $self->vparam( address2 => 'address' ), undef,
            'address2';
        is $self->verror('address2'), 'Wrong format', 'address2 error';

        is $self->vparam( address3 => 'address' ), undef,
            'address3';
        is $self->verror('address3'), 'Wrong format', 'address3 error';

        is $self->vparam( address4 => 'address' ), undef,
            'address4';
        is $self->verror('address4'), 'Value not defined', 'address4 error';

        is $self->vparam( address5 => 'address' ), undef,
            'address5';
        is $self->verror('address5'), 'Wrong format', 'address5 error';

        is $self->vparam( address6 => 'address' ), undef,
            'address6';
        is $self->verror('address6'), 'Wrong format', 'address6 error';

        my $a7 = $self->vparam( address7 => 'address' );
        is $a7->is_extra, 0,      'is_extra - unknown';
        is $self->verror('address7'), 0, 'address7 no error';

        my $a8 = $self->vparam( address8 => 'address' );
        is $a8->is_extra, 0,      'is_extra - undef';
        is $self->verror('address8'), 0, 'address8 no error';

        my $a9 = $self->vparam( address9 => 'address' );
        is $a9->is_near, 1,         'is_near';
        isa_ok $a9->near, 'ARRAY',  'near';
        is $a9->near->address,  $address2,  'near address';
        is $a9->near->lon,      $lon2,      'near lon';
        is $a9->near->lat,      $lat2,      'near lat';
        is $self->verror('address9'), 0, 'address9 no error';

        my $a10 = $self->vparam(address10 => 'address');
        is $a10->address, 'Россия, Москва, Новороссийская, 8', 'address utf8';
        is $a10->lon, 37.759475, 'lon';
        is $a10->lat, 55.679201, 'lat';
        is $self->verror('address10'), 0, 'address10 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/json/vparam", form => {
        address1    => $json,
        address2    => "[]",
        address3    => "[null]",
        address4    => encode_json([$address, $lon, $lat]),
        address5    => "null",
        address6    => "",
        address7    => $json7,
        address8    => $json8,
        address9    => $json9,

        address10   =>
            '[null,"p","Россия, Москва, Новороссийская, 8","37.759475","55.679201","ru"]'
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address json real';
{
    $t->app->routes->post("/test/address/json/real/vparam")->to(cb => sub {
        my ($self) = @_;

        my $a = $self->vparam( address1 => 'address' );
        is $a->address,     'Россия, Москва, Воронежская, 38/43',   'address';
        is $a->lon,         '37.742669',                            'lon';
        is $a->lat,         '55.609859',                            'lat';
        is $a->md5,         undef,                                  'md5';
        is $a->fullname,    'Россия, Москва, Воронежская, 38/43'.
                            ' : 37.742669 , 55.609859',
                            'fullname';
        is $a->id,          '2034755',                              'id';
        is $a->type,        'p',                                    'type';
        is $a->lang,        'ru',                                   'lang';
        is $a->opt,         undef,                                  'opt';
        is $self->verror('address1'), 0, 'address1 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/json/real/vparam", form => {
        address1    => '["'.
            '2034755","p","Россия, Москва, Воронежская, 38/43","37.742669",'.
            '"55.609859","ru"'.
        ']',
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

