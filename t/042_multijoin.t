#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 10;
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
        $self->log->level( $ENV{MOJO_LOG_LEVEL} = 'warn' );
        $self->plugin('Vparam');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'multijoin';
{
    $t->app->routes->post("/test/multijoin/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam(
            int1        => 'int',
            optional    => 1,
            multijoin   => ',',
        ), undef, 'int1 empty';

        is $self->vparam(
            int2        => 'int',
            optional    => 1,
            multijoin   => ',',
        ), 111, 'int2 not array';

        is $self->vparam(
            int3        => 'int',
            multiline   => 1,
            multijoin   => ',',
        ), '1,2,3', 'int3 miltiline';

        is $self->vparam(
            int4        => 'int',
            array       => 1,
            multijoin   => ',',
        ), '1,2,3', 'int4 array';

        is $self->vparam(
            int5        => 'int',
            multijoin   => ',',
        ), '1,2,3', 'int5 many values';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/multijoin/vparam", form => {

        int1      => "",
        int2      => "111",
        int3      => "1 \n 2  \r\n3",
        int4      => [1, 2, 3],
        int5      => [1, 2, 3],

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

