#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 15;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Vparam';
    use_ok 'Digest::MD5', qw(md5_hex);
}

my $md5 = md5_hex 'SECRET' . 'United States, New York:-75.610703,42.93709 ';

note 'address not signed';
{
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

    $t->app->routes->post("/test/address/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( address1 => 'address' ),
            ['United States, New York', -75.610703, 42.93709],
                'address1';
        is_deeply $self->vparam( address2 => 'address' ),
            ['United States, New York', -75.610703, 42.93709],
                'address2';
        is_deeply $self->vparam( address3 => 'address' ),
            ['United States, New York', -75.610703, 42.93709, $md5],
                'address3';
        is_deeply $self->vparam( address4 => 'address' ),
            ['United States, New York', -75.610703, 42.93709, 'BAD'],
                'address4';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/vparam", form => {
        address1    => 'United States, New York:-75.610703,42.93709',
        address2    => 'United States, New York:-75.610703,42.93709 []',
        address3    => "United States, New York:-75.610703,42.93709 [$md5]",
        address4    => 'United States, New York:-75.610703,42.93709 [BAD]',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address signed';
{
    {
        package MyApp2;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('Vparam', {address_secret => 'SECRET'});
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp2');
    ok $t, 'Test Mojo created with address signing';

    $t->app->routes->post("/test/address/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( address1 => 'address' ), undef,
            'address1';
        is $self->vparam( address2 => 'address' ), undef,
            'address2';
        is_deeply $self->vparam( address3 => 'address' ),
            ['United States, New York', -75.610703, 42.93709, $md5],
                'address3';
        is $self->vparam( address4 => 'address' ), undef,
            'address4';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/vparam", form => {
        address1    => 'United States, New York:-75.610703,42.93709',
        address2    => 'United States, New York:-75.610703,42.93709 []',
        address3    => "United States, New York:-75.610703,42.93709 [$md5]",
        address4    => 'United States, New York:-75.610703,42.93709 [BAD]',
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

