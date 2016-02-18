#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 9;
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

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

