#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 39;
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

note 'regexp';
{
    $t->app->routes->post("/test/regexp/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str3 => qr{^[\w\s]{0,20}$} ), 'aaa111bbb222 ccc333',
            'regexp for str3="..."';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/regexp/vparam", form => {
        str3    => 'aaa111bbb222 ccc333',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'callback';
{
    $t->app->routes->post("/test/callback/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( str4 => sub {"bbbfff555"} ) , 'bbbfff555',
            'sub for str4="..."';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/callback/vparam", form => {
        str4    => 'aaa111bbb222 ccc333',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'complex syntax';
{
    $t->app->routes->post("/test/complex/vparam")->to( cb => sub {
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

    $t->post_ok("/test/complex/vparam", form => {
        int1    => undef,
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vparams';
{
    $t->app->routes->post("/test/1/vparams")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        is $self->vparams(int6 => 'int', str5 => 'str')->{int6}, 555,
            'int6=555';
        is $self->vparams(int6 => 'int', str5 => 'str')->{str5}, 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/1/vparams", form => {
        int6    => 555,
        str5    => 'kkll',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'more vparams';
{
    $t->app->routes->post("/test/2/vparams")->to( cb => sub {
        my ($self) = @_;

        isa_ok $self->vparams(int6 => 'int', str5 => 'str'), 'HASH';
        is $self->vparams(int6 => 'int', str5 => 'str')->{int6}, 555,
            'int6=555';
        is $self->vparams(int6 => 'int', str5 => 'str')->{str5}, 'kkll',
            'str5="kkll"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/2/vparams", form => {
        int6    => 555,
        str5    => 'kkll',
    })-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort default values';
{
    $t->app->routes->post("/test/1/vsort")->to( cb => sub {
        my ($self) = @_;

        is $self->vsort()->{page}, 1,                'page = 1';
        is $self->vsort()->{oby}, 1,                 'oby = 1';
        is $self->vsort()->{ods}, 'ASC',             'ods = ASC';
        is $self->vsort()->{rws}, 25,                'rws = 25';

        is $self->vsort(-sort => ['col1', 'col2'])->{oby}, 'col1',
            'oby = "col1"';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/1/vsort", form => {})-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'vsort not default values';
{
    $t->app->routes->post("/test/2/vsort")->to( cb => sub {
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

    $t->post_ok("/test/2/vsort", form => {
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

