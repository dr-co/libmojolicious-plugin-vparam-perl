#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 7;
use Encode qw(decode encode);

use DateTime;
use DateTime::Format::DateParse;
use Mail::RFC822::Address;
use List::MoreUtils qw(any);

BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    require_ok 'Mojolicious';
    require_ok 'DateTime';
    require_ok 'DateTime::Format::DateParse';
    require_ok 'Mail::RFC822::Address';
    require_ok 'List::MoreUtils';
    require_ok 'Test::Compile';
}

ok $Mojolicious::VERSION >= 2.23,       'Mojolicious version >= 2.23';


=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut
