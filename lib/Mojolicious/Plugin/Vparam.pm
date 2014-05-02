package Mojolicious::Plugin::Vparam;

use strict;
use warnings;
use utf8;
use 5.10.0;

use Mojo::Base 'Mojolicious::Plugin';
use Carp;
use DateTime;
use DateTime::Format::DateParse;
use Mail::RFC822::Address;
use Digest::MD5                     qw(md5_hex);
use Encode                          qw(encode_utf8);
use List::MoreUtils                 qw(any);

our $VERSION = '0.15';

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Vparam - Mojolicious plugin validator for GET/POST data.

=head1 SYNOPSIS

    # Get one parameter
    $param1 = $self->vparam(date => 'datetime');
    # Or more syntax
    $param2 = $self->vparam(page => {type => 'int', default => 1});
    # Or more simple syntax
    $param2 = $self->vparam(page => 'int', default => 1);

    # Arrays
    $param3 = $self->vparam(array1 => '@int');
    $param4 = $self->vparam(array2 => 'array[numeric]');
    # The array will come if more than one value
    $param5 = $self->vparam(array3 => 'str');

    # Get many parameters
    %params = $self->vparams(
        # Simple syntax
        name        => 'str',
        password    => qr{^\w{,32}$},
        myparam     => sub {
            my ($self, $param) = @_;
            return ($param eq 'ok') ?1 :0;
        },

        # More syntax
        from        => { type => 'date', default => '' },
        to          => { type => 'date', default => '' },
        id          => { type => 'int' },
        money       => { regexp => qr{^\d+(?:\.\d{2})?$} },
        myparam     => { post => sub {
            my ($self, $param) = @_;
            return ($param eq 'ok') ?1 :0;
        } },
        isa         => { type => 'bool', default => 0 },
    );

    # Same as vparams but auto add some more params for table sorting/paging
    %filters = $self->vsort(
        -sort       => ['name', 'date', ...],

        ...
    );

    # Set optional flag
    $param6 = $self->vparam(param6 => 'int', optional => 1);
    %params = $self->vparams(
        -optional   => 1,
        param7      => 'int',
        param8      => 'int',
    );

    # Get a errors hash by params name
    my %errors = $self->verrors;

=head1 DESCRIPTION

This module use simple paramters types str, int, email, bool, etc. to validate.
Instead of many other modules you not need add specific validation subs or
rules. Just set parameter type. But if you want sub or rule you can do it too.

=head1 METHODS

=head2 vsort

Method vsort automatically add some keys.

=over

=item page

Page number $PARAM_PAGE. Default: 1.

=item oby

Column number for sorting $PARAM_ORDER_BY. Default: 1.

=item ods

Sort order $PARAM_ORDER_DEST. Default: ASC.

=item rws

Rows on page

=back

=head1 KEYS

You can set a simple mode as in exapmple or full mode. Full mode keys:

=over

=item default

Default value. Default: undef.


=item regexp $mojo, $regexp

Valudator regexp by $regexp.

=item pre $mojo, &sub

Incoming filter sub. Used for primary filtration: string length and trim, etc.
Result will be used as new param value.

=item valid $mojo, &sub

Validation sub. Return 1 if valid, else 0.

=item post $mojo, &sub

Out filter sub. Used to modify value for use in you program. Usually used to
bless in some object.
Result will be used as new param value.

=item type

Parameter type. If set then some filters will be apply.

    int numeric money str date time datetime bool email url phone address

After apply all type filters, regexp and post filters will be apply too if set.

You can force values will arrays by @ prefix or array[]. See for example aboth.

=item array

Force value will array. Default: false.

=item optional

By default all parameters are required. You can change this for parameter by
set "optional".
Then true and value is not passed validation don`t set verrors.

=back

=head1 RESERVED KEYS

=over

=item -sort

Arrayref for sort column names. Usually not all columns visible for users and
you need convert column numbers in names. This also protect you SQL queries
from set too much or too low column number.

=item -optional

Set default optional flag for all params in vparams();

=back

=head1 REGISTER PARAMETERS

=over

=item max

Max value length. Default: 64Kb

=item types

Hash of user defined types

=item rows

Default count rows for -sort. Default: 25

=item phone_country

=item phone_region

=item date

Date format. Default: %F

=item time

Time format. Default: %T

=item datetime

Datetime format. Default: '%F %T %z'

=item optional

Default optional

=item address_secret

Secret for address:points signing. Format: "ADDRESS:LATITUDE,LONGITUDE[MD5]".
MD5 ensures that the coordinates belong to address.

=back

=cut

my $PARAM_PAGE          = 'page';
my $PARAM_ORDER_BY      = 'oby';
my $PARAM_ORDER_DEST    = 'ods';
my $PARAM_ROWS          = 'rws';

my $MAX                 = $ENV{MOJO_MAX_MESSAGE_SIZE} // 65535;
my $ROWS                = 25;


sub register {
    my ($self, $app, $conf) = @_;

    # Конфигурация
    $conf                   ||= {};
    $conf->{max}            ||= $MAX;
    $conf->{types}          ||= {};
    $conf->{rows}           ||= $ROWS;

    $conf->{phone_country}  //= 7;
    $conf->{phone_region}   //= 495;

    $conf->{date}           //= '%F';
    $conf->{time}           //= '%T';
    $conf->{datetime}       //= '%F %T %z';

    $conf->{optional}       //= 0;

    $conf->{address_secret} //= '';

    # Типы данных
    my %types = (
        int     => {
            pre     => sub {
                $_[1] = substr $_[1], 0, $conf->{max};
                ($_[1]) = $_[1] =~ m{(-?\d+)};
                return $_[1];
            },
            valid   => sub {
                defined( $_[1] ) && length $_[1];
            },
            post    => sub {
                return unless defined $_[1];
                return 0 + $_[1];
            },
        },
        numeric => {
            pre     => sub {
                $_[1] = substr $_[1], 0, $conf->{max};
                ($_[1]) = $_[1] =~ m{(-?\d+(?:\.\d*)?)};
                return $_[1];
            },
            valid   => sub {
                defined( $_[1] ) && length $_[1];
            },
            post    => sub {
                return unless defined $_[1];
                return 0.0 + $_[1];
            },
        },
        money   => {
            pre     => sub {
                $_[1] = substr $_[1], 0, $conf->{max};
                ($_[1]) = $_[1] =~ m{(-?\d+(?:\.\d{0,2})?)};
                return $_[1];
            },
            valid   => sub {
                defined( $_[1] ) && length $_[1];
            },
        },
        str     => {
            pre     => sub { substr $_[1], 0, $conf->{max} },
            valid   => sub { defined $_[1] },
        },
        date    => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub { _date($_[1]) ?1 :0 },
            post    => sub {
                return unless defined $_[1];
                return _date($_[1])->strftime( $conf->{date} );
            },
        },
        time    => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub { _date($_[1]) ?1 :0 },
            post    => sub {
                return unless defined $_[1];
                return _date($_[1])->strftime( $conf->{time} );
            },
        },
        datetime => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub { _date($_[1]) ?1 :0 },
            post    => sub {
                return unless defined $_[1];
                return _date($_[1])->strftime( $conf->{datetime} );
            },
        },
        bool    => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub {
                defined( $_[1] ) && $_[1] =~ m{^(?:1|0|yes|no|true|false|)$}i;
            },
            post    => sub {
                return unless defined $_[1];
                return $_[1] =~ m{^(?:1|yes|true)$}i ?1 :0
            },
        },
        email   => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub {
                defined( $_[1] ) && Mail::RFC822::Address::valid( $_[1] );
            },
        },
        url   => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub {
                defined( $_[1] ) && $_[1] =~ m{^https?://[\w-]+(?:\.[\w-])+}i;
            },
        },

        phone => {
            pre     => sub { substr _trim($_[1]), 0, $conf->{max} },
            valid   => sub { _phone($_[1],
                             $conf->{phone_country}, $conf->{phone_region})
                                ?1 :0
            },
            post    => sub {
                return unless defined $_[1];
                return _phone(
                    $_[1], $conf->{phone_country}, $conf->{phone_region});
            },
        },

        address => {
            pre     => sub {
                my $str = substr $_[1], 0, $conf->{max};
                my ($full, $address, $lon, $lat, $md5) = $str =~ m{^
                    (
                        \s*
                        # address
                        (\S.*?)
                        \s*:\s*
                        # latitude
                        (-?\d{1,3}(?:\.\d+)?)
                        \s*,\s*
                        #longitude
                        (-?\d{1,3}(?:\.\d+)?)
                        \s*
                    )
                    # md5
                    (?:\[\s*(\w*)\s*\])?
                    \s*
                $}x;

                return [$address, $lon, $lat, $md5, $full];
            },
            valid   => sub {
                # Check for format
                return 0 unless defined $_[1][0];
                return 0 unless length  $_[1][0];
                return 0 unless defined $_[1][1];
                return 0 unless $_[1][1] >= -90  or $_[1][1] <= 90;
                return 0 unless defined $_[1][2];
                return 0 unless $_[1][2] >= -180 or $_[1][2] <= 180;

                if( $conf->{address_secret} ) {
                    # Check for signing
                    return 0 if ! defined $_[1][3];
                    # Check MD5
                    return 0 unless
                        $_[1][3] eq md5_hex(
                            encode_utf8( $conf->{address_secret} . $_[1][4] ) );
                }

                return 1;
            },
            post   => sub {
                return unless defined $_[1];
                my @result = ($_[1][0], $_[1][1], $_[1][2]);
                push @result, $_[1][3] if $_[1][3];
                return \@result;
            }
        },

        # Add types on the fly
        %{$conf->{types}},
    );

    $app->helper(vparams => sub{
        my ($self, %opts) = @_;

        # Get aviable params names
        my @names = $self->param;

        # Выходные значения параметров
        my %params;

        # Get default optional
        my $def_optional;
        $def_optional = exists $opts{-optional}
            ? delete $opts{-optional} : $conf->{optional};

        for my $name (keys %opts) {

            my ($default, $regexp, $type, $pre, $valid, $post, $optional,
                $array);

            # Получим настройки из хеша
            if( 'HASH' eq ref $opts{$name} ) {
                $default    = $opts{$name}->{default};
                $regexp     = $opts{$name}->{regexp};
                $type       = $opts{$name}->{type};
                $pre        = $opts{$name}->{pre};
                $valid      = $opts{$name}->{valid};
                $post       = $opts{$name}->{post};
                $optional   = $opts{$name}->{optional};
                $array      = $opts{$name}->{array};
            # Либо передан regexp проверки
            } elsif( 'Regexp' eq ref $opts{$name} ) {
                $regexp     = $opts{$name};
            # Либо передана post функция
            } elsif( 'CODE' eq ref $opts{$name} ) {
                $post       = $opts{$name};
            # Либо параметру может быть сразу задан тип
            } elsif( !ref $opts{$name} ) {
                $type       = $opts{$name};
            }

            # Set default optional
            $optional = $def_optional unless defined $optional;

            if( defined $type ) {

                # Set array flag if type have match for array
                if( $type =~ m{^@} or $type =~ m{^array\[(.*?)\]$} ) {
                    s{^(?:array\[|@)(.*?)\]?$}{$1} for $type;
                    $array      = 1;
                }

                # Apply type
                if( exists $types{$type} ) {
                    $pre     = $types{$type}{pre}       unless defined $pre;
                    $valid   = $types{$type}{valid}     unless defined $valid;
                    $post    = $types{$type}{post}      unless defined $post;
                    $default = $types{$type}{default}   unless defined $default;
                } else {
                    confess sprintf 'Type %s is not defined', $type;
                }
            }

            # Get value
            my @orig    = $self->param( $name );
            # Set undefined value if paremeter not set, except arrays
            @orig       = (undef)
                #if ! @orig and (! $array || $name ~~ @names);
                if  !@orig and  (! $array or any { $name eq $_ } @names);

            # Set array if values more that one
            $array      = 1 if @orig > 1;

            my @param;

            # Для всех значений параметра выполним обработку
            for my $index ( 0 .. $#orig ) {
                my $orig = $orig[$index];
                my $param;

                # Если параметр был передан то обработаем его,
                # иначе установм по дефолту
                if( defined $orig ) {
                    $param = $orig;

                    # Apply pre filter
                    $param = $pre->( $self, $param )    if $pre;

                    # Apply validator
                    if($valid && ! $valid->($self, $param) ) {

                        my $error = 1;
                        # Default value always supress error
                        $error = 0 if defined $default;
                        # Disable error on optional and unsended params
                        $error = 0 if $optional and (
                                        !defined( $orig ) or
                                        $orig =~ m{^\s*$} );
                        _error(
                            $self,
                            $name => $param => $orig,
                            $array => $index,
                        ) if $error;

                        # Set default value
                        $param = $default;
                    }

                    # Apply post filter
                    $param = $post->( $self, $param )   if $post;

                    # Если не совпадает с заданным регэкспом то сбрасываем на
                    # дефолтное
                    $param = $default
                        if defined $regexp and $param !~ m{$regexp};

                } else {
                    $param = $default;
                    $param = $post->( $self, $param )   if $post;
                }

                # Запишем полученное значение
                push @param, $param;
            }

            # Error for required empty arrays
            _error($self, $name => undef => undef, $array => undef)
                if $array and ! @orig and ! $optional;

            $params{ $name } = $array ?\@param :$param[0];
        }

        return wantarray ?%params :\%params;
    });

    # Алиас для vparams для одного параметра
    $app->helper(vparam => sub{
        my ($self, $name, @opts) = @_;
        my $params;
        if( @opts == 1 || 'HASH' eq ref $opts[0] ) {
            $params = $self->vparams( $name => $opts[0] );
        } else {
            if( 'Regexp' eq ref $opts[0] ) {
                $params = $self->vparams( $name => { regexp => @opts } );
            } elsif('CODE' eq ref $opts[0]) {
                $params = $self->vparams( $name => { post   => @opts } );
            } else {
                $params = $self->vparams( $name => { type   => @opts } );
            }
        }
        return $params->{$name};
    });

    # Возвращает параметры сортировки
    $app->helper(vsort => sub{
        my ($self, %opts) = @_;

        my $sort = delete $opts{'-sort'};
        confess 'Need a list of columns names'
            if $sort && 'ARRAY' eq ref $opts{'-sort'};

        # Предопределенные параметры
        %opts = (
            $PARAM_PAGE         => {
                type    => 'int',
                default => 1
            },
            $PARAM_ORDER_BY     => {
                type    => 'int',
                default => 0,
                post    => sub { $sort->[ $_[1] ] || $_[1]+1 || 1 },
            },
            $PARAM_ORDER_DEST   => {
                type    => 'str',
                default => 'ASC',
                post    => sub { uc $_[1] },
                regexp  => qr{^(?:asc|desc)$}i,
            },
            $PARAM_ROWS         => {
                type    => 'int',
                default => $conf->{rows},
            },
        %opts);

        my $params = $self->vparams( %opts );
        return wantarray ?%$params :$params;
    });

    # Возвращает хеш ошибок валидации
    $app->helper(verrors => sub{
        my ($self, %opts) = @_;
        my $errors = $self->stash('vparam-verrors') // {};
        return wantarray ?%$errors : scalar keys %$errors;
    });
}

=head2 _error

Add error to global stash

=cut

sub _error($$$$;$$) {
    my ($self, $name => $param => $orig, $array => $index ) = @_;

    my $errors = $self->stash('vparam-verrors');

    if( $array ) {
        $errors->{ $name } = []
            unless exists $errors->{ $name };
        push @{$errors->{ $name }}, {
            index   => $index,
            orig    => $orig,
            pre     => $param,
        };
    } else {
        $errors->{ $name } = {
            orig    => $orig,
            pre     => $param,
        };
    }

    return $self->stash('vparam-verrors' => $errors);
}

=head2 _trim

Trim string

=cut

sub _trim($) {
    my ($string) = @_;
    return unless defined $string;
    s/^\s+//, s/\s+$// for $string;
    return $string;
}

=head2 _date $str

Get a string and return DateTime or undef. Have a hack for parse Russian data
and time.

=cut

sub _date($) {
    my ($str) = @_;

    return unless $str;

    my $dt;

    # Fix fro russian date
    $str =~ s{^(\d{2})\.(\d{2})\.(\d{4})(.*)$}{$3-$2-$1$4};
    # If just time, then add date
    $str = DateTime->now->strftime('%F ') . $str if $str =~ m{^\s*\d{2}:};

    # Parse
    $dt = eval { DateTime::Format::DateParse->parse_datetime( $str ); };
    return if !$dt or $@;

    return $dt;
}

=head2 _phone $phone, $country, $region

Clear phones. Fix first local digit 8 problem.

Return <undef> if phome not correct

=cut

sub _phone($$$) {
    my ($phone, $country, $region) = @_;
    return undef unless $phone;
    for ($phone) {
        s/\D+//g;

        $_ = $region . $_ if 7 == length;

        return undef unless 10 <= length $phone;

        if (11 == length $_) { # have a country code
            s/^8/$country/;
        } elsif (10 == length $_) { # havn`t country code
            s/^/$country/;
        }

        s/^/+/;
    }
    return $phone;
}

1;

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
