package Mojolicious::Plugin::Vparam;
use Mojo::Base 'Mojolicious::Plugin';

use strict;
use warnings;
use utf8;
use version;

use Carp;
use DR::Money;
use Mail::RFC822::Address;
use DateTime;
use DateTime::Format::DateParse;
use POSIX                           qw(strftime);
use Mojo::JSON                      qw(from_json);
use List::MoreUtils                 qw(any firstval);

use Mojolicious::Plugin::Vparam::Address;

our $VERSION = '1.0';

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Vparam - Mojolicious plugin validator for GET/POST data.

=head1 DESCRIPTION

Features:

    * Simple syntax or full featured
    * Many predefined types
    * Support arrays of values
    * Support HTML checkbox as bool
    * Validate all parameters at once and get hash to simple use in any Model
    * Manage valudation errors

This module use simple paramters types str, int, email, bool, etc. to validate.
Instead of many other modules you not need add specific validation subs or
rules. Just set parameter type. But if you want sub or rule you can do it too.

=head1 SYNOPSIS

    # Add plugin in startup
    $self->plugin('Vparam');

    # Use in controller
    $login = $self->vparam(login    => 'str');
    $passw = $self->vparam(password => 'password');

=head1 METHODS

=head2 vparam ...

Get one parameter. By default parameter is required.

    # Simple get one parameter
    $param1 = $self->vparam(date => 'datetime');

    # Or more syntax
    $param2 = $self->vparam(count => {type => 'int', default => 1});
    # Or more simple syntax
    $param2 = $self->vparam(count => 'int', default => 1);

=head2 vparms ...

Get many parameters as hash. By default parameters are required.

    %params = $self->vparams(
        # Simple syntax
        name        => 'str',
        password    => qr{^\w{,32}$},
        myparam     => sub { $_[1] && $_[1] eq 'ok' ? 1 : 0 } },
        someone     => ['one', 'two', 'tree'],

        # More syntax
        from        => { type   => 'date', default => '' },
        to          => { type   => 'date', default => '' },
        id          => { type   => 'int' },
        money       => { regexp => qr{^\d+(?:\.\d{2})?$} },
        myparam     => { post   => sub { $_[1] && $_[1] eq 'ok' ? 1 : 0 } },

        # Checkbox
        isa         => { type => 'bool', default => 0 },
    );

=head2 vsort ...

Like I<vparams> but add some keys to simple use with tables.

    %filters = $self->vsort(
        -sort       => ['name', 'date', ...],

        # next as vparams
        ...
    );

=over

=item page

Page number. Default: 1.

You can set different name by I<vsort_page> config parameter.
If you set undef then parameter is not apply.

=item rws

Rows on page. Default: 25.

You can set different name by I<vsort_rws> config parameter.
You can set different default by I<vsort_rows> config parameter.
If you set undef then parameter is not apply.

=item oby

Column number for sorting. Default: 1 - in many cases first database
column is primary key.
If you set undef then parameter is not apply.

You can set different name by I<vsort_oby> config parameter.

=item ods

Sort order ASC|DESC. Default: ASC.

You can set different name by I<vsort_ods> config parameter.
If you set undef then parameter is not apply.

=back

=head2 verror $name

Get parameter error string. Return 0 if no error.

    print $self->verror('myparam') || 'Ok';

=head2 verrors

Return erorrs count in scalar context. In list context return erorrs hash.

    # List context get hash
    my %errors = $self->verrors;

    # Scalar context get count
    die 'Errors!' if $self->verrors;

=head2 vtype $name, %opts

Set new type $name if defined %opts. Else return type $name definition.

=head1 CONFIGURATION

=over

=item types

You can simple add you own types.
Just set this parameters as HashRef with new types definition.

=item vsort_page

Parameter name for current page number in I<vsort>. Default: page.

=item vsort_rws

Parameter name for current page rows count in I<vsort>. Default: rws.

=item rows

Default rows count for I<vsort_rws>. Default: 25.

=item vsort_oby

Parameter name for current order by I<vsort>. Default: oby.

=item vsort_ods

Parameter name for current order destination I<vsort>. Default: ods.

=item ods

Default order destination for I<vsort_rws>. Default: ASC.

=item phone_country

Phone country. Default: empty.

=item phone_region

Phone region. Default: empty.

=item date

Date format for strftime. Default: %F.
if no format specified, return L<DateTime> object.

=item time

Time format for strftime. Default: %T.
if no format specified, return L<DateTime> object.

=item datetime

Datetime format for strftime. Default: '%F %T %z'.
if no format specified, return L<DateTime> object.

=item optional

By default all parameters are required. You can change this by set this
parameter as true.

=item address_secret

Secret for address:points signing. Format: "ADDRESS:LATITUDE,LONGITUDE[MD5]".
MD5 ensures that the coordinates belong to address.

=item password_min

Minimum password length. Default: 8.

=back

=cut

=head1 TYPES

List of supported types:

=over

=cut

=item int

Signed integer

=cut

sub _check_int($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

=item numeric or number

Signed number

=cut

sub _check_numeric($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Wrong format'               unless $_[0] =~ m{^[-+]?\d+(?:\.\d*)?$};
    return 0;
}

=item money

Get L<DR::Money> object for proper money operations.

=cut

sub _check_money($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];

    my $numeric = _check_numeric $_[0];
    return $numeric if $numeric;

    return 'Invalid fractional part'
        if $_[0] =~ m{\.} && $_[0] !~ m{\.\d{0,2}$};
    return 0;
}

=item percent

Unsigned number: 0 <= percent <= 100.

=cut

sub _check_percent($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];

    my $numeric = _check_numeric $_[0];
    return $numeric if $numeric;

    return 'Value must be greater than 0'   unless $_[0] >= 0;
    return 'Value must be less than 100'    unless $_[0] <= 100;
    return 0;
}

=item str

Trimmed text. Must be non empty if required.

=cut

sub _check_str($) {
    return 'Value is not defined'       unless defined $_[0];
    return 0;
}

=item text

Any text. No errors.

=cut

sub _check_text($) {
    return _check_str $_[0];
}

=item password

String with minimum length from I<password_min>.
Must content characters and digits.

=cut

sub _check_password($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf 'The length should be greater than %s', $_[1]
        unless length( $_[0] ) >= $_[1];

    return 'Value must contain characters and digits'
        unless $_[0] =~ m{\d} and $_[0] =~ m{\D};

    return 0;
}

=item uuid

Standart 32 length UUID. Return in lower case.

=cut

sub _check_uuid($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Wrong format'
        unless $_[0] =~ m{^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$}i;
    return 0;
}

=item date

Get date. Parsed from many formats.
See I<date> configuration parameter for result format.
See L<DateTime::Format::DateParse> and even more.

=cut

sub _check_date($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

=item time

Get time. Parsed from many formats.
See I<time> configuration parameter for result format.
See L<DateTime::Format::DateParse> and even more.

=cut

sub _check_time($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

=item datetime

Get full date and time. Parsed from many formats.
See I<datetime> configuration parameter for result format.
See L<DateTime::Format::DateParse> and even more.

=cut

sub _check_datetime($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

=item bool

Boolean value. Can be used to get value from checkbox or another sources.

HTML forms do not send checbox if it checked off.
You need always set default value to supress error if checkbox not checked:

    $self->vparam(mybox => 'bool', default => 0);

=cut

sub _check_bool($) {
    return 'Wrong format'               unless defined $_[0];
    return 0;
}

=item email

Email adress.

=cut

sub _check_email($) {
    return 'Value not defined'          unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Wrong format'
        unless Mail::RFC822::Address::valid( $_[0] );
    return 0;
}

=item url

Get url as L<Mojo::Url> object.

=cut

sub _check_url($) {
    return 'Value not defined'          unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Protocol not set'           unless $_[0]->scheme;
    return 'Host not set'               unless $_[0]->host;
    return 0;
}

=item phone

Phone in international format.

You can set default country I<phone_country> and region I<phone_country> codes.
Then you users can input shortest number.
But this is not work if you site has i18n.

=cut

sub _check_phone($) {
    return 'Value not defined'          unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'The number should be in the format +...'
        unless $_[0] =~ m{^\+\d};
    return 'The number must be a minimum of 11 digits'
        unless $_[0] =~ m{^\+\d{11}};
    return 'The number should be no more than 16 digits'
        unless $_[0] =~ m{^\+\d{11,16}(?:\D|$)};
    return 'Wrong format'
        unless $_[0] =~ m{^\+\d{11,16}(?:[pw]\d+)?$};
    return 0;
}

=item json

JSON incapsulated as form parameter.

=cut

sub _check_json($) {
    return 'Wrong format'           unless defined $_[0];
    return 0;
}

=item address

Location address. Two forms are parsed: string and json.
Can verify adress sign to trust source.

=cut

sub _check_address($;$) {
    return 'Value not defined'          unless defined $_[0];
    return 'Wrong format'               unless ref $_[0];
    return 'Wrong format'               unless defined $_[0]->address;
    return 'Wrong format'               unless length  $_[0]->address;

    my $lon = _check_lon( $_[0]->lon );
    return $lon if $lon;

    my $lat = _check_lat( $_[0]->lat );
    return $lat if $lat;

    return 'Unknown source'             unless $_[0]->check( $_[1] );
    return 0;
}

=item lon

Longitude.

=cut

sub _check_lon($) {
    return 'Value not defined'     unless defined $_[0];

    my $numeric = _check_numeric $_[0];
    return $numeric if $numeric;

    return 'Value should not be less than -180°'    unless $_[0] >= -180;
    return 'Value should not be greater than 180°'  unless $_[0] <= 180;
    return 0;
}

=item lat

Latilude.

=cut

sub _check_lat($) {
    return 'Value not defined'      unless defined $_[0];

    my $numeric = _check_numeric $_[0];
    return $numeric if $numeric;

    return 'Value should not be less than -90°'     unless $_[0] >= -90;
    return 'Value should not be greater than 90°'   unless $_[0] <= 90;
    return 0;
}

=item inn

RU: Taxpayer Identification Number

=cut

sub _check_inn($) {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^(?:\d{10}|\d{12})$};

    my @str = split '', $_[0];
    if( @str == 10 ) {
        return 'Checksum error'
            unless $str[9] eq
                (((
                    2 * $str[0] + 4 * $str[1] + 10 * $str[2] + 3 * $str[3] +
                    5 * $str[4] + 9 * $str[5] + 4  * $str[6] + 6 * $str[7] +
                    8 * $str[8]
                ) % 11 ) % 10);
        return 0;
    } elsif( @str == 12 ) {
        return 'Checksum error'
            unless $str[10] eq
                (((
                    7 * $str[0] + 2 * $str[1] + 4 * $str[2] + 10 * $str[3] +
                    3 * $str[4] + 5 * $str[5] + 9 * $str[6] + 4  * $str[7] +
                    6 * $str[8] + 8 * $str[9]
                ) % 11 ) % 10)
                && $str[11] eq
                (((
                    3  * $str[0] + 7 * $str[1] + 2 * $str[2] + 4 * $str[3] +
                    10 * $str[4] + 3 * $str[5] + 5 * $str[6] + 9 * $str[7] +
                    4  * $str[8] + 6 * $str[9] + 8 * $str[10]
                ) % 11 ) % 10);
        return 0;
    }
    return 'Must be 10 or 12 digits';
}

=item kpp

RU: Code of reason for registration

=cut

sub _check_kpp($) {
    return 'Value not defined'      unless defined $_[0];
    return 'Value not set'          unless length  $_[0];
    return 'Wrong format'           unless $_[0] =~ m{^\d{9}$};
    return 0;
}

=back

=cut


=head1 ATTRIBUTES

You can set a simple mode as in example or full mode. Full mode keys:

=over

=item default

Default value. Default: undef.


=item regexp $mojo, $regexp

Valudator regexp by $regexp.

=item pre $mojo, &sub

Incoming filter sub. Used for primary filtration: string length and trim, etc.
Result will be used as new param value.

=item valid $mojo, &sub

Validation sub. Return 0 if valid, else string of error.

=item post $mojo, &sub

Out filter sub. Used to modify value for use in you program. Usually used to
bless in some object.
Result will be used as new param value.

=item type

Parameter type. If set then some filters will be apply.

    See L<TYPES>

After apply all type filters, regexp and post filters will be apply too if set.

=item array

Force value will array. Default: false.

You can force values will arrays by B<@> prefix or B<array[...]>.

    # Arrays
    $param1 = $self->vparam(array1 => '@int');
    $param2 = $self->vparam(array2 => 'array[int]');
    $param3 = $self->vparam(array3 => 'int', array => 1);

    # The array will come if more than one value incoming
    $param4 = $self->vparam(array4 => 'int');

=item optional

By default all parameters are required. You can change this for parameter by
set "optional".
Then true and value is not passed validation don`t set verrors.

    # Simple vparam
    $param6 = $self->vparam(myparam => 'int', optional => 1);

    # Set one in vparams
    %params = $self->vparams(
        myparam     => { type => 'int', optional => 1 },
    );

    # Set all in vparams
    %params = $self->vparams(
        -optional   => 1,
        param1      => 'int',
        param2      => 'int',
    );

=cut

=item min

Check minimum parameter value.

=cut

sub _min($$) {
    my ($value, $min) = @_;
    return sprintf "Value should not be less than %s", $min
        unless $value >= $min;
    return 0;
}

=item max

Check maximum parameter value.

=cut

sub _max($$) {
    my ($value, $max) = @_;
    return sprintf "Value should not be greater than %s", $max
        unless $value <= $max;
    return 0;
}

=item range

Check parameter value to be in range.

=cut

sub _range($$$) {
    my ($value, $minimum, $maximum) = @_;

    my $min = _min $value => $minimum;
    return $min if $min;

    my $max = _max $value => $maximum;
    return $max if $max;

    return 0;
}

# Regexp
sub _like($$) {
    my ($value, $re) = @_;
    return 'Value not defined'      unless defined $value;
    return 'Wrong format'           unless $value =~ $re;
    return 0;
}

=item in

Check parameter value to be in list of defined values.

=cut

sub _in($$) {
    my ($value, $array) = @_;
    confess 'Not ArrayRef'          unless 'ARRAY' eq ref $array;

    return 'Value not defined'      unless defined $value;
    return 'Wrong value'            unless any {$value eq $_} @$array;

    return 0;
}

=back

=cut

=head1 RESERVED ATTRIBUTES

=over

=item -sort

List of column names for I<vsort>. Usually not all columns visible for users and
you need convert column numbers in names. This also protect you SQL queries
from set too much or too low column number.

=item -optional

Set default optional flag for all params in L<vparams> and I<vsort>;

=back

=cut


# Utils
sub _trim($) {
    my ($str) = @_;
    return undef unless defined $str;
    s{^\s+}{}, s{\s+$}{} for $str;
    return $str;
}

# Parsers
sub _parse_bool($) {
    my ($str) = @_;
    # HTML forms do not transmit if checkbox off
    return 0 unless defined $str;
    return 0 unless length  $str;
    return 0 if $str =~ m{^(?:0|no|false|fail)$}i;
    return 1 if $str =~ m{^(?:1|yes|true|ok)$}i;
    return undef;
}

sub _parse_int($) {
    my ($str) = @_;
    return undef unless defined $str;
    my ($int) = $str =~ m{([-+]?\d+)};
    return $int;
}

sub _parse_number($) {
    my ($str) = @_;
    return undef unless defined $str;
    my ($number) = $str =~ m{([-+]?\d+(?:\.\d*)?)};
    return $number;
}

# Get a string and return DateTime or undef.
# Have a hack for parse Russian data and time.
sub _parse_date($;$) {
    my ($str, $tz) = @_;

    return undef unless defined $str;
    s{^\s+}{}, s{\s+$}{} for $str;
    return undef unless length $str;

    my $dt;

    if( $str =~ m{^\d+$} ) {
        $dt = DateTime->from_epoch( epoch => int $str );
    } elsif( $str =~ m{^[\+\-]\d+$} ) {
        my $minutes = int $str;
        $dt = DateTime->now();
        $dt->add(minutes => $minutes);
    } else {
        # RU format
        $str =~ s{^(\d{1,2})\.(\d{1,2})\.(\d{4})(.*)$}{$3-$2-$1$4};
        # If looks like time add it
        $str = DateTime->now->strftime('%F ') . $str if $str =~ m{^\s*\d{2}:};

        $dt = eval { DateTime::Format::DateParse->parse_datetime( $str ); };
        return undef if !$dt;
        return undef if $@;
    }

    # Set timezone
    $tz //= strftime '%z', localtime;
    $dt->set_time_zone( $tz );

    return $dt;
}

sub _parse_address($) {
    return Mojolicious::Plugin::Vparam::Address->parse( $_[0] );
}

sub _parse_url($) {
    return Mojo::URL->new( $_[0] );
}

sub _parse_json($) {
    my ($str) = @_;
    return undef unless defined $str;
    return undef unless length  $str;

    my $data = eval{ from_json $str };
    warn $@ and return undef if $@;

    return $data;
}

sub _parse_phone($$$) {
    my ($str, $country, $region) = @_;
    return undef unless $str;

    # Clear
    s{[.,]}{w}g, s{[^0-9pw]}{}ig, s{w{2,}}{w}ig, s{p{2,}}{p}ig for $str;

    # Split
    my ($phone, $pause, $add) = $str =~ m{^(\d+)([wp])?(\d+)?$}i;
    return undef unless $phone;

    # Add country and region codes if defined
    $phone = $region  . $phone  if $region  and 11 > length $phone;
    $phone = $country . $phone  if $country and 11 > length $phone;
    return undef unless 10 <= length $phone;

    $str = '+' . $phone;
    $str = $str . lc $pause     if defined $pause;
    $str = $str . $add          if defined $add;

    return $str;
}

# Plugin
sub register {
    my ($self, $app, $conf) = @_;

    $conf                   ||= {};

    $conf->{types}          ||= {};

    $conf->{vsort_page}     ||= 'page';
    $conf->{vsort_rws}      ||= 'rws';
    $conf->{rows}           ||= 25;
    $conf->{vsort_oby}      ||= 'oby';
    $conf->{vsort_ods}      ||= 'ods';
    $conf->{ods}            ||= 'ASC';

    $conf->{phone_country}  //= '';
    $conf->{phone_region}   //= '';

    $conf->{date}           //= '%F';
    $conf->{time}           //= '%T';
    $conf->{datetime}       //= '%F %T %z';

    $conf->{optional}       //= 0;

    $conf->{address_secret} //= '';

    $conf->{password_min}   //= 8;

    $conf->{types} = {
        # Numbers
        int         => {
            pre     => sub{ _parse_int      $_[1] },
            valid   => sub{ _check_int      $_[1] },
            post    => sub{ defined         $_[1]   ? 0 + $_[1] : undef },
        },
        numeric     => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_numeric  $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
        },
        money       => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_money    $_[1] },
        },
        percent     => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_percent  $_[1] },
        },
        lon         => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_lon      $_[1] },
        },
        lat         => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_lat      $_[1] },
        },

        # Text
        str         => {
            pre     => sub{ _trim           $_[1] },
            valid   => sub{ _check_str      $_[1] },
        },
        text        => {
            valid   => sub{ _check_str      $_[1] },
        },
        password    => {
            valid   => sub{ _check_password $_[1], $conf->{password_min} },
        },
        uuid        => {
            pre     => sub{ _trim           $_[1] },
            valid   => sub{ _check_uuid     $_[1] },
            post    => sub{ defined         $_[1] ? lc $_[1] : undef },
        },

        # Date and Time
        date        => {
            pre     => sub { _parse_date _trim  $_[1] },
            valid   => sub { _check_date        $_[1] },
            post    => sub {
                return unless defined $_[1];
                return $conf->{date}
                    ? $_[1]->strftime( $conf->{date} )
                    : $_[1];
            },
        },
        time        => {
            pre     => sub { _parse_date _trim  $_[1] },
            valid   => sub { _check_time        $_[1] },
            post    => sub {
                return unless defined $_[1];
                return $conf->{time}
                    ? $_[1]->strftime( $conf->{time} )
                    : $_[1];
            },
        },
        datetime    => {
            pre     => sub { _parse_date _trim  $_[1] },
            valid   => sub { _check_datetime    $_[1] },
            post    => sub {
                return unless defined $_[1];
                return $conf->{datetime}
                    ? $_[1]->strftime( $conf->{datetime} )
                    : $_[1];
            },
        },

        # Bool
        bool        => {
            pre     => sub { _parse_bool _trim  $_[1] },
            valid   => sub { _check_bool        $_[1] },
        },

        # Internet
        email       => {
            pre     => sub { _trim              $_[1] },
            valid   => sub { _check_email       $_[1] },
        },
        url         => {
            pre     => sub { _parse_url _trim   $_[1] },
            valid   => sub { _check_url         $_[1] },
        },

        # Phone
        phone       => {
            pre     => sub { _parse_phone
                                _trim( $_[1] ),
                                $conf->{phone_country},
                                $conf->{phone_region}
                           },
            valid   => sub { _check_phone       $_[1] },
        },

        # Structures
        json        => {
            pre     => sub { _parse_json        $_[1] },
            valid   => sub { _check_json        $_[1] },
        },
        address     => {
            pre     => sub { _parse_address     $_[1] },
            valid   => sub { _check_address     $_[1], $conf->{address_secret}},
        },

        # RU
        inn         => {
            pre     => sub { _trim              $_[1] },
            valid   => sub { _check_inn         $_[1] },
        },
        kpp         => {
            pre     => sub { _trim              $_[1] },
            valid   => sub { _check_kpp         $_[1] },
        },

        # Add extra user types
        %{$conf->{types}},
    };
    # Aliases
    $conf->{types}{number} = $conf->{types}{numeric};

    # Get or set type
    $app->helper(vtype => sub {
        my ($self, $name, %opts) = @_;
        return $conf->{types}{$name} = \%opts if %opts;
        return $conf->{types}{$name};
    });

    # Get or set config parameters
    $app->helper(vconf => sub {
        my ($self, $name, $value) = @_;
        return $conf->{$name} = $value if @_ > 2;
        return $conf->{$name};
    });

    # Many parameters
    $app->helper(vparams => sub{
        my ($self, %params) = @_;

        # Get aviable params names
        my @names = $self->param;

        # Выходные значения параметров
        my %result;

        # Get default optional
        my $def_optional;
        $def_optional = exists $params{-optional}
            ? delete $params{-optional} : $conf->{optional};

        for my $name (keys %params) {

            my ($default, $regexp, $type, $pre, $valid, $post, $optional,
                $array);

            # Получим настройки из хеша
            if( 'HASH' eq ref $params{$name} ) {
                $default    = $params{$name}->{default};
                $regexp     = $params{$name}->{regexp};
                $type       = $params{$name}->{type};
                $pre        = $params{$name}->{pre};
                $valid      = $params{$name}->{valid};
                $post       = $params{$name}->{post};
                $optional   = $params{$name}->{optional};
                $array      = $params{$name}->{array};
            # Либо передан regexp проверки
            } elsif( 'Regexp' eq ref $params{$name} ) {
                $valid      = sub { _like( $_[1], $params{$name} ) };
            # Либо передана post функция
            } elsif( 'CODE' eq ref $params{$name} ) {
                $post       = $params{$name};
            # Либо передан список
            } elsif( 'ARRAY' eq ref $params{$name} ) {
                $valid      = sub { _in( $_[1], $params{$name} ) };
            # Либо параметру может быть сразу задан тип
            } elsif( !ref $params{$name} ) {
                $type       = $params{$name};
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
                if( exists $conf->{types}{$type} ) {
                    $pre     = $conf->{types}{$type}{pre}       unless defined $pre;
                    $valid   = $conf->{types}{$type}{valid}     unless defined $valid;
                    $post    = $conf->{types}{$type}{post}      unless defined $post;
                    $default = $conf->{types}{$type}{default}   unless defined $default;
                } else {
                    confess sprintf 'Type %s is not defined', $type;
                }
            }

            # Get value
            my @input;

            if( version->new($Mojolicious::VERSION) < version->new(5.28) ) {
                @input = $self->param( $name );
            } else {
                @input = @{ $self->every_param( $name ) };
            }
            # Set undefined value if paremeter not set, except arrays
            @input       = (undef)
                if  !@input and  (! $array or any { $name eq $_ } @names);

            # Set array if values more that one
            $array      = 1 if @input > 1;

            my @output;

            # Для всех значений параметра выполним обработку
            for my $index ( 0 .. $#input ) {
                my $in = $input[$index];
                my $out;

                # Если параметр был передан то обработаем его,
                # иначе установм по дефолту
                if( defined $in ) {
                    $out = $in;

                    # Apply pre filter
                    $out = $pre->( $self, $out )    if $pre;

                    # Apply validator
                    if($valid && ( my $error = $valid->($self, $out) ) ) {

                        # Default value always supress error
                        undef $error if defined $default;
                        # Disable error on optional and unsended params
                        undef $error if $optional and (
                                            !defined( $in ) or
                                            $in =~ m{^\s*$}
                                        );
                        _error(
                            $self,
                            $name => $out => $in,
                            $array => $index,
                            $error,
                        ) if $error;

                        # Set default value
                        $out = $default;
                    }

                    # Apply post filter
                    $out = $post->( $self, $out )   if $post;

                    # Если не совпадает с заданным регэкспом то сбрасываем на
                    # дефолтное
                    if( defined $regexp ) {
                        if( my $error = _like( $out, $regexp) ) {
                            $out = $default;
                            _error(
                                $self,
                                $name => $out => $in,
                                $array => $index,
                                $error,
                            );
                        }
                    }

                } else {
                    $out = $default;
                    $out = $post->( $self, $out )   if $post;
                }

                # Запишем полученное значение
                push @output, $out;
            }

            # Error for required empty arrays
            _error($self, $name => undef => undef, $array => undef, 'Empty array')
                if $array and ! @input and ! $optional;

            $result{ $name } = $array ? \@output : $output[0];
        }

        return wantarray ? %result : \%result;
    });

    # One parameter
    $app->helper(vparam => sub{
        my ($self, $name, $def, %attr) = @_;

        confess 'Parameter name required'               unless defined $name;
        confess 'Parameter type or definition required' unless defined $def;

        my $result;

        unless( %attr ) {
            $result = $self->vparams( $name => $def );
        } elsif( 'HASH' eq ref $def ) {
            # Ignore attrs not in HashRef
            $result = $self->vparams( $name => $def );
        } elsif( 'Regexp' eq ref $def ) {
            $def    = sub { _like( $_[1], $def ) };
            $result = $self->vparams( $name => { valid  => $def, %attr } );
        } elsif('CODE' eq ref $def) {
            $result = $self->vparams( $name => { post   => $def, %attr } );
        } elsif('ARRAY' eq ref $def) {
            $def    = sub { _in( $_[1], $def ) };
            $result = $self->vparams( $name => { valid  => $def, %attr } );
        } else {
            $result = $self->vparams( $name => { type   => $def, %attr } );
        }

        return $result->{$name};
    });

    # Same as vparams but add standart table sort parameters for:
    # ORDER BY, LIMIT, OFFSET
    $app->helper(vsort => sub{
        my ($self, %attr) = @_;

        my $sort = delete $attr{'-sort'};
        confess 'Key "-sort" must be ArrayRef'
            if defined($sort) and 'ARRAY' ne ref $sort;

        $attr{ $conf->{vsort_page} } = {
            type        => 'int',
            default     => 1,
        } if defined $conf->{vsort_page};

        $attr{ $conf->{vsort_rws} } = {
            type        => 'int',
            default     => $conf->{rows},
        } if defined $conf->{vsort_rws};

        $attr{ $conf->{vsort_oby} } = {
            type        => 'int',
            default     => 0,
            post        => sub { $sort->[ $_[1] ] or ($_[1] + 1) or 1 },
        } if defined $conf->{vsort_oby};

        $attr{ $conf->{vsort_ods} } = {
            type        => 'str',
            default     => $conf->{ods},
            post        => sub { uc $_[1] },
            regexp      => qr{^(?:asc|desc)$}i,
        } if defined $conf->{vsort_ods};

        my $result = $self->vparams( %attr );
        return wantarray ? %$result : $result;
    });

    # Return true if parameter $name has error
    $app->helper(verror => sub{
        my ($self, $name, $index) = @_;
        my $errors = $self->stash('vparam-verrors') // {};
        return 0 unless exists $errors->{$name};

        if('ARRAY' eq ref $errors->{$name}) {
            # If no index set return errors count
            return scalar @{$errors->{$name}} unless defined $index;
            # Find error by index
            my $error = firstval {$_->{index} == $index} @{$errors->{$name}};
            return $error ? $error->{message} : 0;
        } else {
            return $errors->{$name}
                ? $errors->{$name}{message}         : 0;
        }
    });

    # Return all errors as Hash or errors count in scalar context.
    $app->helper(verrors => sub{
        my ($self) = @_;
        my $errors = $self->stash('vparam-verrors') // {};
        return wantarray ? %$errors : scalar keys %$errors;
    });

    return;
}

# Add error to global stash
sub _error($$$$;$$) {
    my ($self, $name => $param => $orig, $array => $index, $error ) = @_;

    my $errors = $self->stash('vparam-verrors') // {};

    if( $array ) {
        $errors->{ $name } = [] unless exists $errors->{ $name };
        push @{$errors->{ $name }}, {
            index   => $index,
            orig    => $orig,
            pre     => $param,
            message => $error,
        };
    } else {
        $errors->{ $name } = {
            orig    => $orig,
            pre     => $param,
            message => $error,
        };
    }

    return $self->stash('vparam-verrors' => $errors);
}


1;

=head1 RESTRICTIONS

    * Version 1.0 invert L<valid> behavior: now checker return 0 if no error
      or description string if has.

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
