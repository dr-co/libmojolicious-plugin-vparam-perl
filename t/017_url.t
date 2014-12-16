#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 11;
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

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

