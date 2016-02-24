package Mojolicious::Plugin::Vparam::Address;

use strict;
use warnings;
use utf8;
use 5.10.0;

use Mojo::JSON                      qw(decode_json);
use Digest::MD5                     qw(md5_hex);
use Encode                          qw(encode_utf8);

sub new {
    my ($class, $opts) = @_;
    return bless $opts => $class;
}

=head2 parse $str

Parse address from string

=cut

sub parse {
    my ($class, $str) = @_;

    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt);

    if( $str =~ m{^\s*\[} and $str =~ m{\]\s*$} ) {
        # JSON format

        # utf8 hack
        eval { utf8::downgrade $str } if utf8::is_utf8 $str;
        eval { utf8::encode $str }    if utf8::is_utf8 $str;

        # Try parse
        my $json = eval{ decode_json $str; };
        if( not $@ and $json and 'ARRAY' eq ref($json)) {
            $full       = sprintf '%s : %s , %s',
                            $json->[2]//'', $json->[3]//'', $json->[4]//'';
            $address    = $json->[2];
            $lon        = $json->[3];
            $lat        = $json->[4];
            $id         = $json->[0];
            $type       = $json->[1];
            $lang       = $json->[5];
            $opt        = 'ARRAY' eq ref($json->[6])
                            ? $class->new($json->[6])
                            : $json->[6];
        } else {
            warn $@ if $@;
        }
    } else {
        # Text format
        ($full, $address, $lon, $lat, $md5) = $str =~ m{^
            (
                \s*
                # address
                (\S.*?)
                \s*:\s*
                # longitude
                (-?\d{1,3}(?:\.\d+)?)
                \s*,\s*
                # latitude
                (-?\d{1,3}(?:\.\d+)?)
                \s*
            )
            # md5
            (?:\[\s*(\w*)\s*\])?
            \s*
        $}x;
    }

    return $class->new([
        $address, $lon, $lat, $md5, $full, $id, $type, $lang, $opt
    ]);
}

=head2 check $secret

Check address sign for $secret

=cut

sub check {
    my ($self, $secret) = @_;
    return 1 unless $secret;
    return 1 if $self->type and $self->type eq 'p';
    return 0 unless defined $self->md5;
    return $self->md5 eq md5_hex( encode_utf8( $secret . $self->fullname ) );
}

sub address     { return $_[0]->[0]; }
sub lon         { return $_[0]->[1]; }
sub lat         { return $_[0]->[2]; }
sub md5         { return $_[0]->[3]; }
sub fullname    { return $_[0]->[4]; }

sub id          { return $_[0]->[5]; }
sub type        { return $_[0]->[6]; }
sub lang        { return $_[0]->[7]; }

sub opt         { return $_[0]->[8]; }

sub is_extra {
    my ($self) = @_;
    return 0 unless defined $self->opt;
    return 1 if not ref( $self->opt ) and $self->opt eq 'extra';
    return 0;
}

sub is_near {
    my ($self) = @_;
    return 0 unless defined $self->opt;
    return 1 if ref( $self->opt );
    return 0;
}

sub near {
    my ($self) = @_;
    return unless $self->is_near;
    return $self->opt;
}

1;

=AUTHORS

Dmitry E. Oboukhov <unera@debian.org>
Roman V. Nikolaev <rshadow@rambler.ru>

=COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This program is free software, you can redistribute it and/or
modify it under the terms of the Artistic License.

=cut
