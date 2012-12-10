use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More;
plan tests => 1;
use Test::Compile;

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";
}

subtest 'Perl modules' => sub {
    all_pm_files_ok();
};
