package Mojolicious::Plugin::Vparam;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Plugin';
use Carp;
use DateTime;
use DateTime::Format::DateParse;
use Mail::RFC822::Address;
use List::MoreUtils qw(any);

our $VERSION = '0.5';

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Vparam - Mojolicious plugin validator for GET/POST data.

=head1 SYNOPSIS

    # Get one parameter
    my $param1 = $self->vparam('date' => 'datetime');
    # Or more syntax
    my $param2 = $self->vparam('page' => {type => 'int', default => 1});
    # Or more simple syntax
    my $param2 = $self->vparam('page' => 'int', default => 1);

    # Get many parameters
    my %params = $self->vparams(
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
    my %filters = $self->vsort(
        -sort       => ['name', 'date', ...],

        ...
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

    int str date time datetime money bool email url phone

After apply all type filters, regexp and post filters will be apply too if set.

=back

=head1 RESERVED KEYS

=over

=item -sort

Arrayref for sort column names. Usually not all columns visible for users and
you need convert column numbers in names. This also protect you SQL queries
from set too much or too low column number.

=back

=cut

my $PARAM_PAGE          = 'page';
my $PARAM_ORDER_BY      = 'oby';
my $PARAM_ORDER_DEST    = 'ods';
my $PARAM_ROWS          = 'rws';

my $MAX                 = 65535;
my $ROWS                = 25;


sub register {
    my ($self, $app, $conf) = @_;

    # Конфигурация
    $conf           ||= {};
    $conf->{max}    ||= $MAX;
    $conf->{types}  ||= {};
    $conf->{rows}   ||= $ROWS;

    $conf->{phone_country}  //= 7;
    $conf->{phone_region}   //= 495;

    # Типы данных
    my %types = (
        int     => {
            pre     => sub {
                $_[1] = substr $_[1], 0, $conf->{max};
                ($_[1]) = $_[1] =~ m{(-?\d+)};
                return $_[1];
            },
            valid   => sub {
                defined( $_[1] ) && $_[1] =~ m{^-?\d+$};
            },
        },
        str     => {
            pre     => sub { substr $_[1], 0, $conf->{max} },
            valid   => sub { defined( $_[1] ) },
        },
        date    => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub { date_parse($_[1]) ?1 :0 },
            post    => sub { $_[1] ?date_parse($_[1])->strftime('%F'):undef },
        },
        time    => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub { date_parse($_[1]) ?1 :0 },
            post    => sub { $_[1] ?date_parse($_[1])->strftime('%T'):undef },
        },
        datetime => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub { date_parse($_[1]) ?1 :0 },
            post    => sub { $_[1] ?date_parse($_[1])->strftime('%F %T'):undef},
        },
        money   => {
            pre     => sub {
                $_[1] = substr $_[1], 0, $conf->{max};
                ($_[1]) = $_[1] =~ m{(-?\d+(?:\.\d+)?)};
                return $_[1];
            },
            valid   => sub {
                defined( $_[1] ) && $_[1] =~ m{^-?\d+(?:\.\d+)?$};
            },
        },
        bool    => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub {
                defined( $_[1] ) && $_[1] =~ m{^(?:1|0|yes|no|true|false|)$}i;
            },
            post    => sub { $_[1] =~ m{^(?:1|yes|true)$}i ?1 :0},
        },
        email   => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub {
                defined( $_[1] ) && Mail::RFC822::Address::valid( $_[1] );
            },
        },
        url   => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub {
                defined( $_[1] ) && $_[1] =~ m{^https?://[\w-]+(?:\.[\w-])+}i;
            },
        },

        phone => {
            pre     => sub { substr trim($_[1]), 0, $conf->{max} },
            valid   => sub { clean_phone($_[1],
                             $conf->{phone_country}, $conf->{phone_region})
                                ?1 :0
            },
            post    => sub {
                $_[1]
                    ?clean_phone($_[1], $conf->{phone_country},
                                 $conf->{phone_region})
                    :undef
            },
        },

        # Возможность "на лету" добавлять свой тип данных
        %{$conf->{types}},
    );

    $app->helper(vparams => sub{
        my ($self, %opts) = @_;

        # Выходные значения параметров
        my %params;
        # Хеш ошибок хранится в глобальном стеше. Сбрасывается на каждом новом
        # вызове функции.
        my %errors;
        $self->stash('vparam-verrors' => \%errors);

        for my $name (keys %opts) {

            my ($default, $regexp, $type, $pre, $valid, $post);

            # Получим настройки из хеша
            if( 'HASH' eq ref $opts{$name} ) {
                $default = $opts{$name}->{default};
                $regexp  = $opts{$name}->{regexp};
                $type    = $opts{$name}->{type};
                $pre     = $opts{$name}->{pre};
                $valid   = $opts{$name}->{valid};
                $post    = $opts{$name}->{post};
            # Либо передан regexp проверки
            } elsif( 'Regexp' eq ref $opts{$name} ) {
                $regexp  = $opts{$name};
            # Либо передана post функция
            } elsif( 'CODE' eq ref $opts{$name} ) {
                $post    = $opts{$name};
            # Либо параметру может быть сразу задан тип
            } elsif( !ref $opts{$name} ) {
                $type    = $opts{$name};
            }

            confess sprintf 'Type %s is not defined', $type
                if defined $type and !(any {$type eq $_} keys %types);

            # Получим значение фильтра
            my @orig  = $self->param( $name );
            my @param;

            # Для всех значений параметра выполним обработку
            for my $orig ( @orig ?@orig :(undef) ) {
                my $param;

                # Если параметр был передан то обработаем его,
                # иначе установм по дефолту
                if( defined $orig ) {
                    $param = $orig;

                    # Применение типа
                    $pre    = $types{$type}{pre}    if $type && !$pre;
                    $valid  = $types{$type}{valid}  if $type && !$valid;
                    $post   = $types{$type}{post}   if $type && !$post;

                    # Применение фильтров
                    $param = $pre->( $self, $param )    if $pre;
                    # Применение валидаторов
                    if( $valid && ! $valid->($self, $param) ) {
                        $param = $default;
                        # Запишем ошибку
                        $errors{ $name }        = {};
                        $errors{ $name }{orig}  = $orig;
                    }
                    # Применение постобработки
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

            # Если парметром был массив то сохраним как массив, а для
            # обычного параметра как скаляр
            $params{ $name } = (@orig > 1) ?\@param :$param[0];
        }

        return wantarray ?%params :\%params;
    });

    # Алиас для vparams для одного параметра
    $app->helper(vparam => sub{
        my ($self, $name, @opts) = @_;
        my $params;
        if( @opts == 1 || 'HASH' eq $opts[0] ) {
            $params = $self->vparams( $name => $opts[0] );
        } else {
            if( 'Regexp' eq ref $opts[0] ) {
                $params = $self->vparams( $name => { regexp => @opts } );
            } elsif('CODE' eq ref $opts[0]) {
                $params = $self->vparams( $name => { post => @opts   } );
            } else {
                $params = $self->vparams( $name => { type => @opts   } );
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
        my $errors = $self->stash('vparam-verrors');
        return wantarray ?%$errors : scalar keys %$errors;
    });
}

sub trim($) {
    my ($string) = @_;
    return unless defined $string;
    s/^\s+//, s/\s+$// for $string;
    return $string;
}

=head2 date_parse $str

Get a string and return DateTime or undef. Have a hack for parse Russian data
and time.

=cut

sub date_parse($) {
    my ($str) = @_;

    return unless $str;

    my $dt;

    my $tzone = DateTime::TimeZone->new( name => 'local' );

    # Take a russian date if possible
    my ($day, $month, $year, $hour, $minute, $second, $tz) =
        $str =~ m{^
            (\d{2})\.(\d{2})\.(\d{4})
            (?:
                \s+
                (\d{2}):(\d{2}):(\d{2})?(?:\.\d+)?
            )?
            (?:
                \s+
                (.*)
            )?
        $}xs;
    if( $day and $month and $year ) {
        $dt = eval {
            DateTime->new(
                year        => $year,
                month       => $month,
                day         => $day,
                hour        => $hour    || 0,
                minute      => $minute  || 0,
                second      => $second  || 0,
                time_zone   => ($tz)
                                ?DateTime::TimeZone->new( name => $tz )
                                :$tzone,
            );
        };
        return if !$dt or $@;
    } else {
        $dt = eval {
            DateTime::Format::DateParse->parse_datetime( $str, $tzone->name );
        };
        return if !$dt or $@;
    }

    return $dt;
}

=head2 clean_phone $phone, $country, $region

Clear phones. Fix first local digit 8 problem.

Return <undef> if phome not correct

=cut

sub clean_phone($$$) {
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
