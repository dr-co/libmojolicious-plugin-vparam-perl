#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 8;
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

note 'reaname';
{
    $t->app->routes->post("/reaname")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1        => {type => 'int', as => 'my1'},
            int2        => {type => 'int', as => 'my2'},
            unknown     => {type => 'int', as => 'my3'},
        );
        is_deeply
            \%params,
            {my1 => undef, my2 => 123, my3 => undef},
            'all params renamed'
        ;

        is $self->vparam(int1       => 'int'), undef,   'int1';
        is $self->vparam(int2       => 'int'), 123,     'int2';
        is $self->vparam(unknown    => 'int'), undef,   'int3';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/reaname", form => {
        int1    => '',
        int2    => '123',
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

