#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 50;
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

note 'type errors';
{
    $t->app->routes->post("/test/errors/vparam")->to( cb => sub {
        my ($self) = @_;

        eval { $self->vparam( int1 => 'non_exiting_type') };
        ok $@, 'type not found';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/errors/vparam", form => {
        int1    => 111,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'default supress errors';
{
    $t->app->routes->post("/test/param/default/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int1 => {type => 'int', default => 111} ), 111,
            'default int1';
        is $self->vparam( int2 => {type => 'int', default => 222} ), 222,
            'int2';
        is $self->vparam( int3 => {type => 'int', default => 333} ), 333,
            'int3';

        is $self->verrors, 0, 'no bugs';
        my %errors = $self->verrors;

        ok !$errors{int1}, 'int1 not in errors';
        ok !$errors{int2}, 'int2 not in errors';
        ok !$errors{int3}, 'int3 not in errors';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/param/default/vparam", form => {
        int1    => 'ddd',
        int2    => '',
        int3    => undef,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'param definition errors';
{
    $t->app->routes->post("/test/param/errors/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply { $self->vparams(
            int1 => 'int',
            int2 => 'int',
            int3 => 'int',
        )}, {
            int1 => undef,
            int2 => undef,
            int3 => undef,
        }, 'vparams';

        is $self->vparam( int4 => {type => 'int'} ), undef, 'int4';
        is $self->vparam( int5 => {type => 'int'} ), undef, 'int5';
        is $self->vparam( int6 => {type => 'int'} ), undef, 'int6';

        is_deeply $self->vparam( array1 => '@int' ), [1, undef, 3, undef],
            'array1';

        is $self->verrors, 7, 'bugs';
        my %errors = $self->verrors;

        ok $errors{int1},               'error int1';
        is $errors{int1}{orig}, 'aaa',  'error int1 orig';
        is $errors{int1}{pre}, undef,   'error int1 pre';
        ok $errors{int2},               'error int2';
        is $errors{int2}{orig}, 'bbb',  'error int2 orig';
        is $errors{int2}{pre}, undef,   'error int2 pre';
        ok $errors{int3},               'error int3';
        is $errors{int3}{orig}, 'ccc',  'error int3 orig';
        is $errors{int3}{pre}, undef,   'error int3 pre';
        ok $errors{int4},               'error int4';
        is $errors{int4}{orig}, '',     'error int4 orig';
        is $errors{int4}{pre}, undef,   'error int4 pre';
        ok $errors{int5},               'error int5';
        is $errors{int5}{orig}, '',     'error int5 orig';
        is $errors{int5}{pre}, undef,   'error int5 pre';
        ok $errors{int6},               'error int6';
        is $errors{int6}{orig}, 'aaa',  'error int6 orig';
        is $errors{int6}{pre}, undef,   'error int6 pre';

#        note explain $self->verrors;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/param/errors/vparam", form => {
        int1    => 'aaa',
        int2    => 'bbb',
        int3    => 'ccc',
        int4    => '',
        int5    => undef,
        int6    => 'aaa',

        array1  => [1, 'aaa', 3, 'ddd'],
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'array errors';
{
    $t->app->routes->post("/test/param/array/vparam")->to( cb => sub {
        my ($self) = @_;

        is_deeply $self->vparam( array1 => '@int' ), [undef],
            'array1';
        is_deeply $self->vparam( array2 => '@int' ), [1, undef, 2],
            'array2';

        is_deeply $self->vparam( unknown => '@int' ), [],
            'unknown';

        my %errors = $self->verrors;
        is scalar keys %errors, 3, 'bugs';


        ok $errors{array1},    'array1 in errors';
        ok $errors{array2},    'array2 in errors';
        ok $errors{unknown},   'unknown in errors';

#        note explain \%errors;

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/param/array/vparam", form => {
        array1  => 'ddd',
        array2  => [1, '', 2],
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

