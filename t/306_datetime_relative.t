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
    use_ok 'DateTime';
    use_ok 'DateTime::Format::DateParse';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('Vparam', {datetime => undef});
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'datetime relative';
{
    $t->app->routes->post("/test/datetime/relative/vparam")->to( cb => sub {
        my ($self) = @_;

        my $datetime0 = DateTime->now(time_zone => 'local')
            ->add(minutes => 15);
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '>=',
            $datetime0->clone->subtract(seconds => 5)->epoch,
            'datetime0';
        cmp_ok
            $self->vparam( datetime0 => 'datetime' )->epoch,
            '<=',
            $datetime0->clone->add(seconds => 5)->epoch,
            'datetime0';
        is $self->verror('datetime0'), 0, 'datetime0 no error';

        my $datetime1 = DateTime->now(time_zone => 'local')
            ->subtract(minutes => 6);
        cmp_ok
            $self->vparam( datetime1 => 'datetime' )->epoch,
            '>=',
            $datetime1->clone->subtract(seconds => 5)->epoch,
            'datetime1';
        cmp_ok
            $self->vparam( datetime1 => 'datetime' )->epoch,
            '<=',
            $datetime1->clone->add(seconds => 5)->epoch,
            'datetime1';
        is $self->verror('datetime1'), 0, 'datetime1 no error';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime/relative/vparam", form => {
        datetime0  => '+15',
        datetime1  => '-6',
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

