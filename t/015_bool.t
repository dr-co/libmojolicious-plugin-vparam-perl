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

note 'bool';
{
    $t->app->routes->post("/test/bool/vparam")->to( cb => sub {
        my ($self) = @_;

        is $self->vparam( bool1 => 'bool' ), 1,         'bool1 = 1';
        is $self->vparam( bool2 => 'bool' ), 1,         'bool2 = True';
        is $self->vparam( bool3 => 'bool' ), 1,         'bool3 = yes';
        is $self->vparam( bool4 => 'bool' ), 0,         'bool4 = 0';
        is $self->vparam( bool5 => 'bool' ), 0,         'bool5 = faLse';
        is $self->vparam( bool6 => 'bool' ), 0,         'bool6 = no';
        is $self->vparam( bool7 => 'bool' ), 0,         'bool7 = ""';
        is $self->vparam( bool8 => 'bool' ), 0,         'bool8 = undef';
        is $self->vparam( bool9 => 'bool' ), 1,         'bool9 = True';

        is $self->vparam( unknown => {type => 'bool', default => 1}), 1,
                                            'undefined unknown = 1 by default';
        is $self->vparam( unknown => 'bool' ), undef,  'undefined unknown';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/bool/vparam", form => {
        bool1       => '1',
        bool2       => 'True',
        bool3       => 'yes',
        bool4       => '0',
        bool5       => 'faLse',
        bool6       => 'no',
        bool7       => '',
        bool8       => undef,
        bool9       => '  True  ',
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

