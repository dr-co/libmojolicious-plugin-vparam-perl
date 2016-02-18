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

        is $self->vparam( str0 => 'str', regexp => qr{abc} ),
            undef,                                              'str0 empty';
        is $self->verror('str0'), 'Wrong format',               'str0 error';

        is $self->vparam( str1 => 'str', regexp => qr{abc} ),
            'abcdef',                                           'str1 string';
        is $self->verror('str1'), 0,                            'str1 no error';

        is $self->vparam( str2 => 'str', regexp => qr{abc} ),
            undef,                                              'str2 not match';
        is $self->verror('str2'), 'Wrong format',               'str2 error';


        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/regexp/vparam", form => {
        str0    => '',
        str1    => 'abcdef',
        str2    => '123456',
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

