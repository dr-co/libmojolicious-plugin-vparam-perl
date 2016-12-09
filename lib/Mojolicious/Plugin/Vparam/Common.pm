package Mojolicious::Plugin::Vparam::Common;
use Mojo::Base -strict;
use Mojo::Loader;

use base qw(Exporter);
our @EXPORT         = qw(trim);
our @EXPORT_OK      = qw(char_shift load_class params);
our %EXPORT_TAGS    = (all => [@EXPORT, @EXPORT_OK]);

our $CHAR_SHIFT = ord('A') - 10;

sub trim($) {
    my ($str) = @_;
    return undef unless defined $str;
    s{^\s+}{}, s{\s+$}{} for $str;
    return $str;
}

# Shift for convert ASCII char position to simple sequence 0,1,2...9,A,B,C,,,
sub char_shift() {
    return $CHAR_SHIFT;
}

# Around deprication
sub load_class($) {
    return Mojo::Loader::load_class( $_[0] ) if Mojo::Loader->can('load_class');
    return Mojo::Loader->new->load( $_[0] )  if Mojo::Loader->can('load');
    die 'Looks like Mojo again depricate module Mojo::Loader';
}

# Around deprication
sub params($$) {
    return @{ $_[0]->every_param( $_[1] ) } if $_[0]->can('every_param');
    return $_[0]->param( $_[1] )            if $_[0]->can('param');
    die 'Looks like Mojo again depricate module Mojo::Controller';
}

1;
