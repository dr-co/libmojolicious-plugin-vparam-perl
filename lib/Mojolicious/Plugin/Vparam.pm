package Mojolicious::Plugin::Vparam;
use Mojo::Base 'Mojolicious::Plugin';

use strict;
use warnings;
use utf8;
use version;

use Carp;
use Mail::RFC822::Address;
use DateTime;
use DateTime::Format::DateParse;
use Mojo::JSON;
use List::MoreUtils                 qw(any firstval);

use Mojolicious::Plugin::Vparam::Address;

our $VERSION = '1.4';

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Vparam - Mojolicious plugin validator for GET/POST data.

=head1 DESCRIPTION

Features:

=over

=item *

Simple syntax or full featured

=item *

Many predefined types

=item *

Filters complementary types

=item *

Support arrays of values

=item *

Support HTML checkbox as bool

=item *

Validate all parameters at once and get hash to simple use in any Model

=item *

Manage validation errors

=item *

Full Mojolicious::Validator::Validation integration

=back

This module use simple parameters types B<str>, B<int>, B<email>, B<bool>,
etc. to validate.
Instead of many other modules you mostly not need add specific validation
subs or rules.
Just set parameter type. But if you want sub or regexp you can do it too.

=head1 SYNOPSIS

    # Add plugin in startup
    $self->plugin('Vparam');

    # Use in controller
    $login = $self->vparam(login    => 'str');
    $passw = $self->vparam(password => 'password', size => [8, 100]);
    $email = $self->vparam(email    => 'email', optional => 1);

=head1 METHODS

=head2 vparam

Get one parameter. By default parameter is required.

    # Simple get one parameter
    $param1 = $self->vparam(date => 'datetime');

    # Or more syntax
    $param2 = $self->vparam(count => {type => 'int', default => 1});
    # Or more simple syntax
    $param2 = $self->vparam(count => 'int', default => 1);

=head2 vparams

Get many parameters as hash. By default all parameters are required.

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

=head2 vsort

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

    # Get error
    print $self->verror('myparam') || 'Ok';
    # Set error
    $self->verror('myparam', {message => 'Error message'})

=head2 verrors

Return erorrs count in scalar context. In list context return erorrs hash.

    # List context get hash
    my %errors = $self->verrors;

    # Scalar context get count
    die 'Errors!' if $self->verrors;

=head2 vtype $name, %opts

Set new type $name if defined %opts. Else return type $name definition.

    # Get type
    $self->vtype('mytype');

    # Set type
    # pre   - get int
    # valid - check for not empty
    # post  - force number
    $self->vtype('mytype',
        pre     => sub {
            my ($self, $param) = @_;
            return int $param // '';
        },
        valid   => sub {
            my ($self, $param) = @_;
            return length $param ? 0 : 'Invalid'
        },
        post    => sub {
            my ($self, $param) = @_;
            return 0 + $param;
        }
    );

=head2 vfilter $name, $sub

Set new filter $name if defined %opts. Else return filter $name definition.

    # Get filter
    $self->vfilter('myfilter');

    # Set filter
    $self->vfilter('myfilter', sub {
        my ($self, $param, $expression) = @_;
        return $param eq $expression ? 0 : 'Invalid';
    });

Filter sub must return 0 if parameter value is valid. Or error string if not.

=head1 SIMPLE SYNTAX

You can use the simplified syntax instead of specifying the type,
simply by using an expression instead.

=over

=item I<REGEXP>

Apply as B<regexp> filter. No type verification, just match.

=item I<CODE> $mojo, $value

Apply as B<post> function. You need manual verify and set error.

=item I<ARRAY>

Apply as B<in> filter. No type verification, just match.

=back

=head1 CONFIGURATION

=over

=item types

You can simple add you own types.
Just set this parameters as HashRef with new types definition.

=item filters

You can simple add you own filters.
Just set this parameters as HashRef with new filters definition.

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

=item mojo_validator

Enable L<Mojolicious::Validator::Validation> integration.

=back

=cut

=head1 TYPES

List of supported types:

=over

=cut

=item int

Signed integer. Use L</min> filter for unsigned.

=cut

sub _check_int($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 0;
}

=item numeric or number

Signed number. Use L</min> filter for unsigned.

=cut

sub _check_numeric($) {
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return 'Wrong format'               unless $_[0] =~ m{^[-+]?\d+(?:\.\d*)?$};
    return 0;
}

=item money

Get money. Use L</min> filter for unsigned.

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

Input formats:

=over

=item *

Timestamp.

=item *

Relative from now in format C<[+-] DD HH:MM:SS>. First sign required.

=over

=item *

Minutes by default. Example: C<+15> or C<-6>.

=item *

Minutes and seconds. Example: C<+15:44>.

=item *

Hours. Example: C<+3:15:44>.

=item *

Days. Example: C<+8 3:15:44>.

=back

Values are given in arbitrary range.
For example you can add 400 minutes and 300 seconds: C<+400:300>.

=item *

All that can be obtained L<DateTime::Format::DateParse>.

=item *

Russian date format like C<DD.MM.YYYY>

=back

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

Valid values are:

=over

=item

I<TRUE> can be 1, yes, true, ok

=item

I<FALSE> can be 0, no, false, fail

=back

Other values get error.

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

Phone in international format. Support B<wait>, B<pause> and B<additional>.

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

    # Supress myparam to be undefined and error
    $self->vparam(myparam => 'str', default => '');

=item pre $mojo, &sub

Incoming filter sub. Used for primary filtration: string length and trim, etc.
Result will be used as new param value.

Usually, if you need this attribute, you need to create a new type.

=item valid $mojo, &sub

Validation sub. Return 0 if valid, else string of error.

Usually, if you need this attribute, you need to create a new type.

=item post $mojo, &sub

Out filter sub. Used to modify value for use in you program. Usually used to
bless in some object.
Result will be used as new param value.

=item type

Parameter type. If set then some filters will be apply. See L</TYPES>.

    $self->vparam(myparam => 'datetime');

After the application of the type used filters.

=item array

Force value will array. Default: false.

You can force values will arrays by B<@> prefix or B<array[...]>.

    # Arrays
    $param1 = $self->vparam(array1 => '@int');
    $param2 = $self->vparam(array2 => 'array[int]');
    $param3 = $self->vparam(array3 => 'int', array => 1);

    # The array will come if more than one value incoming
    # Example: http://mysite.us?array4=123&array4=456...
    $param4 = $self->vparam(array4 => 'int');

=item optional

By default all parameters are required. You can change this for parameter by
set "optional".
Then true and value is not passed validation don`t set verrors.

    # Simple vparam
    # myparam is undef but no error.
    $param6 = $self->vparam(myparam => 'int', optional => 1);

    # Set one in vparams
    %params = $self->vparams(
        myparam     => { type => 'int', optional => 1 },
    );

    # Set all in vparams
    %params = $self->vparams(
        -optional   => 1,
        param1      => 'int',
        param2      => 'str',
    );

=back

=head1 RESERVED ATTRIBUTES

=over

=item -sort

List of column names for I<vsort>. Usually not all columns visible for users and
you need convert column numbers in names. This also protect you SQL queries
from set too much or too low column number.

=item -optional

Set default optional flag for all params in L</vparams> and L</vsort>.

=back

=cut

=head1 FILTERS

Filters are used in conjunction with types for additional verification.

=cut

=over

=item min

Check minimum parameter value.

    # Error if myparam less than 10
    $self->vparam(myparam => 'int', min => 10);

=cut

sub _min($$) {
    my $numeric = _check_numeric $_[0];
    return $numeric if $numeric;

    return sprintf "Value should not be greater than %s", $_[1]
        unless $_[0] >= $_[1];
    return 0;
}

=item max

Check maximum parameter value.

    # Error if myparam greater than 100
    $self->vparam(myparam => 'int', max => 100);

=cut

sub _max($$) {
    my $numeric = _check_numeric $_[0];
    return $numeric if $numeric;

    return sprintf "Value should not be less than %s", $_[1]
        unless $_[0] <= $_[1];
    return 0;
}

=item range

Check parameter value to be in range.

    # Error if myparam less than 10 or greater than 100
    $self->vparam(myparam => 'int', range => [10, 100]);

=cut

sub _range($$$) {
    my $min = _min $_[0] => $_[1];
    return $min if $min;

    my $max = _max $_[0] => $_[2];
    return $max if $max;

    return 0;
}

=item regexp

Check parameter to be match for regexp

    # Error if myparam not equal "abc" or "cde"
    $self->vparam(myparam => 'int', regexp => qr{^(abc|cde)$});

=cut

sub _like($$) {
    return 'Value not defined'      unless defined $_[0];
    return 'Wrong format'           unless $_[0] =~ $_[1];
    return 0;
}

=item in

Check parameter value to be in list of defined values.

    # Error if myparam not equal "abc" or "cde"
    $self->vparam(myparam => 'str', in => [qw(abc cde)]);

=cut

sub _in($$) {
    confess 'Not ArrayRef'          unless 'ARRAY' eq ref $_[1];

    return 'Value not defined'      unless defined $_[0];
    return 'Wrong value'            unless any {$_[0] eq $_} @{$_[1]};

    return 0;
}

=item size

Check maximum length in utf8.

    # Error if value is an empty string
    $self->vparam(myparam => 'str', size => [1, 100]);

=cut

sub _size($$$) {
    my ($value, $min, $max) = @_;
    return 'Value is not defined'       unless defined $_[0];
    return 'Value is not set'           unless length  $_[0];
    return sprintf "Value should not be less than %s", $min
        unless $min <= length $value;
    return sprintf "Value should not be longer than %s", $max
        unless $max >= length $value;
    return 0;
}

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
        $dt = DateTime->from_epoch( epoch => int $str, time_zone => 'local' );
    } elsif( $str =~ m{^[+-]} ) {
        my @relative = $str =~ m{
            ^([+-])             # sign
            \s*
            (?:(\d+)\s+)?       # days
            (?:(\d+):)??        # hours
            (\d+)               # minutes
            (?::(\d+))?         # seconds
        $}x;
        $dt = DateTime->now(time_zone => 'local');
        my $sub = $relative[0] eq '+' ? 'add' : 'subtract';
        $dt->$sub(days      => int $relative[1])    if defined $relative[1];
        $dt->$sub(hours     => int $relative[2])    if defined $relative[2];
        $dt->$sub(minutes   => int $relative[3])    if defined $relative[3];
        $dt->$sub(seconds   => int $relative[4])    if defined $relative[4];
    } else {
        # RU format
        $str =~ s{^(\d{1,2})\.(\d{1,2})\.(\d{4})(.*)$}{$3-$2-$1$4};
        # If looks like time add it
        $str = DateTime->now(time_zone => 'local')->strftime('%F ') . $str
            if $str =~ m{^\s*\d{2}:};

        $dt = eval { DateTime::Format::DateParse->parse_datetime( $str ); };
        return undef if !$dt;
        return undef if $@;
    }

    # Always local timezone
    $tz //= DateTime->now(time_zone => 'local')->strftime('%z');
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



    my $data = eval{
        if( version->new($Mojolicious::VERSION) < version->new(5.54) ) {
            return Mojo::JSON->new->decode( $str );
        } else {
            return Mojo::JSON::decode_json( $str );
        }
    };
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
    $conf->{filters}        ||= {};

    $conf->{vsort_page}     ||= 'page';
    $conf->{vsort_rws}      ||= 'rws';
    $conf->{rows}           ||= 25;
    $conf->{vsort_oby}      ||= 'oby';
    $conf->{vsort_ods}      ||= 'ods';
    $conf->{ods}            ||= 'ASC';

    $conf->{phone_country}  //= '';
    $conf->{phone_region}   //= '';

    $conf->{date}           = '%F'          unless exists $conf->{date};
    $conf->{time}           = '%T'          unless exists $conf->{time};
    $conf->{datetime}       = '%F %T %z'    unless exists $conf->{datetime};

    $conf->{optional}       //= 0;

    $conf->{address_secret} //= '';

    $conf->{password_min}   //= 8;

    $conf->{mojo_validator} //= 1;

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
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
        },
        percent     => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_percent  $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
        },
        lon         => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_lon      $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
        },
        lat         => {
            pre     => sub{ _parse_number   $_[1] },
            valid   => sub{ _check_lat      $_[1] },
            post    => sub{ defined         $_[1] ? 0.0 + $_[1] : undef },
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

    $conf->{filters} = {
        regexp      => sub { _like      $_[1], $_[2] },
        in          => sub { _in        $_[1], $_[2] },
        min         => sub { _min       $_[1], $_[2] },
        max         => sub { _max       $_[1], $_[2] },
        range       => sub { _range     $_[1], $_[2][0], $_[2][1] },
        size        => sub { _size      $_[1], $_[2][0], $_[2][1] },
        # Add extra user filters
        %{$conf->{filters}},
    };

    # Get or set type
    $app->helper(vtype => sub {
        my ($self, $name, %opts) = @_;
        return $conf->{types}{$name} = \%opts if @_ > 2;
        return $conf->{types}{$name};
    });

    # Get or set filter
    $app->helper(vfilter => sub {
        my ($self, $name, $sub) = @_;
        return $conf->{filters}{$name} = $sub if @_ > 2;
        return $conf->{filters}{$name};
    });

    # Get or set config parameters
    $app->helper(vconf => sub {
        my ($self, $name, $value) = @_;
        return $conf->{$name} = $value if @_ > 2;
        return $conf->{$name};
    });

    # Get or set error for parameter $name
    $app->helper(verror => sub{
        my ($self, $name, @opts) = @_;

        my $errors = $self->stash('vparam-verrors') // {};

        if( @_ <= 2 ) {
            return 0 unless exists $errors->{$name};

            return 'ARRAY' eq ref $errors->{$name}
                ? scalar @{$errors->{$name}}
                : $errors->{$name}{message} // 0
            ;
        } elsif( @_ == 3 ) {
            return 0 unless exists $errors->{$name};

            my $error = 'ARRAY' eq ref $errors->{$name}
                ? firstval {$_->{index} == $opts[0]} @{$errors->{$name}}
                : $errors->{$name}
            ;
            return $error->{message} // 0;
        } else {

            my %attr = %{{@opts}};
            if( $attr{array} ) {
                $errors->{ $name } = [] unless exists $errors->{ $name };
                push @{$errors->{ $name }}, \%attr;
            } else {
                $errors->{ $name } = \%attr;
            }

            if( $conf->{mojo_validator} ) {
                $self->validation->error($name => [$attr{message}]);
            }

            return $self->stash('vparam-verrors' => $errors);
        }
    });

    # Return all errors as Hash or errors count in scalar context.
    $app->helper(verrors => sub{
        my ($self) = @_;
        my $errors = $self->stash('vparam-verrors') // {};
        return wantarray ? %$errors : scalar keys %$errors;
    });

    # Many parameters
    $app->helper(vparams => sub{
        my ($self, %params) = @_;

        # Result
        my %result;

        # Get default optional
        my $optional = exists $params{-optional}
            ? delete $params{-optional}
            : $conf->{optional}
        ;

        for my $name (keys %params) {
            # Param definition
            my $def = $params{$name};

            # Get attibutes
            my %attr;
            if( 'HASH' eq ref $def ) {
                %attr           = %$def;
            } elsif( 'Regexp' eq ref $def ) {
                $attr{regexp}   = $def;
            } elsif( 'CODE' eq ref $def ) {
                $attr{post}     = $def;
            } elsif( 'ARRAY' eq ref $def ) {
                $attr{in}       = $def;
            } elsif( !ref $def ) {
                $attr{type}     = $def;
            }

            # Set default optional
            $attr{optional} = $optional unless defined $attr{optional};

            # Apply type
            if( defined( my $type = $attr{type} ) ) {

                # Set array flag if type have match for array
                if( $type =~ m{^@} ) {
                    s{^@}{} for $type;
                    $attr{array} = 1;
                }
                if( $type =~ m{^array\[(.*?)\]$} ) {
                    s{^array\[(.*?)\]$}{$1} for $type;
                    $attr{array} = 1;
                }

                if( exists $conf->{types}{ $type } ) {
                    for my $key ( keys %{$conf->{types}{ $type }} ) {
                        next if defined $attr{ $key };
                        $attr{ $key } = $conf->{types}{ $type }{ $key };
                    }
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

            # Set undefined value if paremeter not set
            # if array then keep it empty
            @input = (undef) if not @input and not $attr{array};

            # Set array if values more that one
            $attr{array} = 1 if @input > 1;

            # Process on all input values
            my @output;
            for my $index ( 0 .. $#input ) {
                my $in = my $out = $input[$index];

                if( defined $in ) {
                    $out = $in;

                    # Apply pre filter
                    $out = $attr{pre}->( $self, $out )    if $attr{pre};

                    # Apply validator
                    if( $attr{valid} ) {
                        if( my $error = $attr{valid}->($self, $out)  ) {
                            # Set default value if error
                            $out = $attr{default};

                            # Default value always supress error
                            $error = 0 if defined $attr{default};
                            # Disable error on optional
                            if( $attr{optional} ) {
                                # Only if input param not set
                                $error = 0 if not defined $in;
                                $error = 0 if defined($in) and $in =~ m{^\s*$};
                            }

                            $self->verror(
                                $name,
                                %attr,
                                index   => $index,
                                in      => $in,
                                out     => $out,
                                message => $error,
                            ) if $error;
                        }
                    }

                    # Apply post filter
                    $out = $attr{post}->( $self, $out )   if $attr{post};

                    for my $key ( keys %attr ) {
                        # Skip not filters
                        next if $key eq 'type';
                        next if $key eq 'pre';
                        next if $key eq 'valid';
                        next if $key eq 'post';
                        next if $key eq 'optional';
                        next if $key eq 'default';
                        next if $key eq 'array';

                        # Skip unknown attribute
                        next unless $conf->{filters}{ $key };

                        my $error = $conf->{filters}{ $key }->(
                            $self, $out, $attr{ $key }
                        );
                        if( $error ) {
                            # Set default value if error
                            $out = $attr{default};

                            # Default value always supress error
                            $error = 0 if defined $attr{default};
                            # Disable error on optional
                            if( $attr{optional} ) {
                                # Only if input param not set
                                $error = 0 if not defined $in;
                                $error = 0 if defined($in) and $in =~ m{^\s*$};
                            }

                            $self->verror(
                                $name,
                                %attr,
                                index   => $index,
                                in      => $in,
                                out     => $out,
                                message => $error,
                            ) if $error;
                        }
                    }
                } else {
                    $out = $attr{default};
                    $out = $attr{post}->( $self, $out )   if $attr{post};
                }

                # Запишем полученное значение
                push @output, $out;
            }

            # Error for required empty arrays
            $self->verror( $name, %attr, message => 'Empty array' )
                if $attr{array} and not $attr{optional} and not @input;

            $result{ $name } = my $value = $attr{array} ? \@output : $output[0];
            # Mojolicious::Validator::Validation
            $self->validation->output->{$name} = $value
                if $conf->{mojo_validator};
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
            $result = $self->vparams( $name => { regexp => $def, %attr } );
        } elsif('CODE' eq ref $def) {
            $result = $self->vparams( $name => { post   => $def, %attr } );
        } elsif('ARRAY' eq ref $def) {
            $result = $self->vparams( $name => { in     => $def, %attr } );
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

    return;
}

1;

=head1 RESTRICTIONS

=over

=item *

Version 1.0 invert I<valid> behavior: now checker return 0 if no error
or description string if has.

=item *

New errors keys: orig => in, pre => out

=back

=head1 SEE ALSO

L<Mojolicious::Validator::Validation>, L<Mojolicious::Plugin::Human>.

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
