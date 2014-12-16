#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 12;
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

note 'numeric';
{
    $t->app->routes->post("/test/numeric/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( numeric0 => 'numeric' ), 0,         'numeric0';
        is $self->vparam( numeric1 => 'numeric' ), 111.222,   'numeric1';
        is $self->vparam( numeric2 => 'numeric' ), 222,       'numeric2';
        is $self->vparam( numeric3 => 'numeric' ), 333.444,   'numeric3';
        is $self->vparam( numeric4 => 'numeric' ), undef,     'numeric4';
        is $self->vparam( numeric5 => 'numeric' ), undef,     'numeric5';
        is $self->vparam( numeric6 => 'numeric' ), 333,       'numeric6';
        is $self->vparam( numeric7 => 'numeric' ), -333.444,  'numeric7';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/numeric/vparam", form => {

        numeric0    => 0,
        numeric1    => 111.222,
        numeric2    => '222aaa',
        numeric3    => 'bbb333.444bbb',
        numeric4    => 'ccc',
        numeric5    => undef,
        numeric6    => ' 333. ',
        numeric7    => ' -333.444 ',
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

