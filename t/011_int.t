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

note 'int';
{
    $t->app->routes->post("/test/int/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( int0 => 'int' ), 0,         'int0';
        is $self->vparam( int1 => 'int' ), 111,       'int1';
        is $self->vparam( int2 => 'int' ), 222,       'int2';
        is $self->vparam( int3 => 'int' ), 333,       'int3';
        is $self->vparam( int4 => 'int' ), undef,     'int4';
        is $self->vparam( int5 => 'int' ), undef,     'int5';
        is $self->vparam( int6 => 'int' ), 333,       'int6';
        is $self->vparam( int7 => 'int' ), -333,      'int7';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/int/vparam", form => {

        int0    => 0,
        int1    => 111,
        int2    => '222aaa',
        int3    => 'bbb333bbb',
        int4    => 'ccc',
        int5    => undef,
        int6    => ' 333 ',
        int7    => ' -333 ',
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

