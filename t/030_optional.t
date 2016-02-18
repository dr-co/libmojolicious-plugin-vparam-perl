#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 37;
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

note 'required by default';
{
    $t->app->routes->post("/required")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1    => {type => 'int'},
            int2    => {type => 'int'},

            int_ok1 => {type => 'int'},
            int_ok2 => {type => 'int', default => 222},
        );
        is $self->verrors, 2, '2 bug';
        my %errors = $self->verrors;

        is $params{int1},       undef, 'int1';
        ok $errors{int1},       'int1 in errors';

        is $params{int2},       undef, 'int2';
        ok $errors{int2},       'int2 in errors';

        is $params{int_ok1},    111, 'int_ok1';
        ok !$errors{int_ok1},   'int_ok1 not in errors';

        is $params{int_ok2},    222, 'int_ok2';
        ok !$errors{int_ok2},   'int_ok2 not in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/required", form => {
        int1    => '',
        int2    => '   ',

        int_ok1 => 111,
        int_ok2 => '',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'optional';
{
    $t->app->routes->post("/optional")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            int1    => {type => 'int', optional => 1},
            int2    => {type => 'int', optional => 1},

            int_ok1 => {type => 'int', optional => 1},
            int_ok2 => {type => 'int', optional => 1, default => 222},

            int_fail1 => {type => 'int', optional => 1},
        );

        is $self->verrors, 1, 'bugs';
        my %errors = $self->verrors;

        is $params{int1},       undef, 'int1';
        ok !$errors{int1},      'int1 not in errors';

        is $params{int2},       undef, 'int2';
        ok !$errors{int2},      'int2 not in errors';

        is $params{int_ok1},    111, 'int_ok1';
        ok !$errors{int_ok1},   'int_ok1 not in errors';

        is $params{int_ok2},    222, 'int_ok2';
        ok !$errors{int_ok2},   'int_ok2 not in errors';

        is $params{int_fail1},  undef, 'int_fail1';
        ok $errors{int_fail1},  'int_fail1 in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/optional", form => {
        int1    => '',
        int2    => '   ',

        int_ok1 => 111,
        int_ok2 => '',

        int_fail1 => 'ddd',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'full optional';
{
    $t->app->routes->post("/foptional")->to( cb => sub {
        my ($self) = @_;

        my %params = $self->vparams(
            -optional   => 1,
            int1        => {type => 'int'},
            int2        => {type => 'int'},

            int_ok1     => {type => 'int'},
            int_ok2     => {type => 'int', default => 222},

            int_fail1 => {type => 'int', optional => 1},
        );
        is $self->verrors, 1, 'bugs';
        my %errors = $self->verrors;

        is $params{int1},       undef, 'int1';
        ok !$errors{int1},      'int1 not in errors';

        is $params{int2},       undef, 'int2';
        ok !$errors{int2},      'int2 not in errors';

        is $params{int_ok1},    111, 'int_ok1';
        ok !$errors{int_ok1},   'int_ok1 not in errors';

        is $params{int_ok2},    222, 'int_ok2';
        ok !$errors{int_ok2},   'int_ok2 not in errors';

        is $params{int_fail1},  undef, 'int_fail1';
        ok $errors{int_fail1},  'int_fail1 in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/foptional", form => {
        int1    => '',
        int2    => '   ',

        int_ok1 => 111,
        int_ok2 => '',

        int_fail1 => 'ddd',
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

