
package Module::Spec::V2;

# ABSTRACT: Load modules based on V2 specifications
use 5.012;

# use warnings;

our @EXPORT_OK = qw(need_module try_module);

BEGIN {
    require Module::Spec::V0;
    *_generate_code  = \&Module::Spec::V0::_generate_code;
    *_opts           = \&Module::Spec::V0::_opts;
    *_need_module    = \&Module::Spec::V0::_need_module;
    *_require_module = \&Module::Spec::V0::_require_module;
    *_try_module     = \&Module::Spec::V0::_try_module;
    *croak           = \&Module::Spec::V0::croak;
}

state $MODULE_RE  = qr/ [^\W\d]\w*+ (?: :: \w++ )*+ /x;
state $VERSION_RE = qr/ v?+ (?>\d+) (?: [\._] \d+ )*+ /x;

sub parse_module_spec {
    my $spec = pop;
    if ( my ( $m, @v ) = _parse_module_spec($spec) ) {
        my %info = ( module => $m );
        $info{version} = $v[0] if @v;
        return \%info;
    }
    return;
}

sub _parse_module_spec {
    if ( $_[0] =~ m/\A ($MODULE_RE) (?: ~ ($VERSION_RE) )? \z/x ) {
        my ( $m, $v ) = ( $1, $2 );    # Make a copy
        return ($m) unless $v;
        return ( $m, _parse_v_spec($v) );
    }
    elsif ( ref $_[0] eq 'ARRAY' ) {

        croak(qq{Should contain one or two entries})
          unless @{ $_[0] } && @{ $_[0] } <= 2;
        my $m = $_[0][0];
        my ( $m1, @v1 ) = _parse_module_spec($m)
          or croak(qq{Can't parse $m});
        return ( $m1, @v1 ) if @{ $_[0] } == 1;
        my $v = $_[0][1];
        return ( $m1, _parse_version_spec($v) );
    }
    elsif ( ref $_[0] eq 'HASH' ) {

        croak(qq{Should contain a single pair}) unless keys %{ $_[0] } == 1;
        my ( $m, $v ) = %{ $_[0] };
        my ($m1) = _parse_module_spec($m)
          or croak(qq{Can't parse $m});
        return ( $m1, _parse_version_spec($v) );
    }
    return;
}

sub _parse_v_spec { $_[0] eq '0' ? () : ( $_[0] ) }

sub _parse_version_spec {    # Extra sanity check
    unless ( defined $_[0] && $_[0] =~ m/\A $VERSION_RE \z/x ) {
        croak(qq{Invalid version $_[0]});
    }
    goto &_parse_v_spec;
}

# Precomputed for most common case
state $_OPTS = _opts();

# need_module($spec)
# need_module($spec, \%opts)
sub need_module {
    my $opts = @_ > 1 ? _opts(pop) : $_OPTS;

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    return _need_module( $opts, $m, @v );
}

# generate_code($spec, \%opts);
sub generate_code {
    my $opts = @_ > 1 ? pop : {};

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq(Can't parse $_[-1]}));
    return _generate_code( $opts, $m, @v );
}

# try_module($spec)
# try_module($spec, \%opts)
sub try_module {
    my $opts = @_ > 1 ? _opts(pop) : $_OPTS;

    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    return _try_module( $opts, $m, @v );
}

sub need_modules {
    my $op = $_[0] =~ /\A-/ ? shift : '-all';
    state $SUB_FOR = {
        '-all'   => \&_need_all_modules,
        '-any'   => \&_need_any_modules,
        '-oneof' => \&_need_first
    };
    croak(qq{Unknown operator "$op"}) unless my $sub = $SUB_FOR->{$op};
    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        @_ = map { [ $_ => $_[0]{$_} ] } keys %{ $_[0] };
    }
    goto &$sub;
}

sub _need_all_modules {
    map { scalar need_module($_) } @_;
}

sub _need_any_modules {
    my ( @m, $m );
    ( $m = try_module($_) ) && push @m, $m for @_;
    return @m;
}

sub _need_first_module {
    my $m;
    ( $m = try_module($_) ) && return ($m) for @_;
    return;
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Module::Spec::V2 ();
    Module::Spec::V2::need_module('Mango~2.3');

=head1 DESCRIPTION

B<This is alpha software. The API is likely to change.>

=head2 MODULE SPECS

As string

    M
    M~V       minimum match, ≥ V
    M~0       same as M, accepts any version

Example version specs are

    2
    2.3
    2.3.4
    v3.2.3

As a hash ref

    { M => V }      minimum match, ≥ V
    { M => '0' }    accepts any version

As an array ref

    [ M ]
    [ M => V ]      minimum match, ≥ V
    [ M => '0' ]    same as [ M ], accepts any version

=head1 FUNCTIONS

L<Module::Spec::V2> implements the following functions.

=head2 need_module

    $module = need_module('SomeModule~2.3');
    $module = need_module( { SomeModule => '2.3' } );
    $module = need_module( [ SomeModule => '2.3' ] );

    $module = need_module($spec);
    $module = need_module($spec, \%opts);

Loads a module and checks for a version requirement (if any).
Returns the name of the loaded module.

On list context, returns the name of the loaded module
and its version (as reported by C<< $m->VERSION >>).

    ( $m, $v ) = need_module($spec);
    ( $m, $v ) = need_module($spec, \%opts);

These options are currently available:

=over 4

=item require

    require => 1    # default
    require => 0
    require => sub { my ($m, @v) = @_; ... }

Controls whether the specified module should be C<require>d or not.
It can be given as a non-subroutine value, which gets
interpreted as a boolean: true means that the module
should be loaded with C<require> and false means
that no attempt should be made to load it.
This option can also be specified as a subroutine which gets
passed the module name and version requirement (if any)
and which should return true if the module should be loaded
with C<require> or false otherwise.

=back

=head2 need_modules

    @modules = need_modules(@spec);
    @modules = need_modules(-all => @spec);
    @modules = need_modules(-any => @spec);
    @modules = need_modules(-oneof => @spec);

    @modules = need_modules(\%spec);
    @modules = need_modules(-all => \%spec);
    @modules = need_modules(-any => \%spec);
    @modules = need_modules(-oneof => \%spec);

Loads some modules according to a specified rule.

The current supported rules are C<-all>, C<-any> and C<-oneof>.
If none of these are given as the first argument,
C<-all> is assumed.

The specified modules are given as module specs,
either as a  list or as a single hashref.
If given as a list, the corresponding order will be respected.
If given as a hashref, a random order is to be expected.

The behavior of the rules are as follows:

=over 4

=item -all

All specified modules are loaded by C<need_module>.
If successful, returns the names of the loaded modules.

=item -any

All specified modules are loaded by C<try_module>.
Returns the names of the modules successfully loaded.

=item -oneof

Specified modules are loaded by C<try_module>
until a successful load.
Returns (in list context) the name of the loaded module.

=back

=head2 try_module

    $module = try_module('SomeModule~2.3');
    $module = try_module( { SomeModule => '2.3' } );
    $module = try_module( [ SomeModule => '2.3' ] );

    $module = try_module($spec);
    $module = try_module($spec, \%opts);

Tries to load a module (if available) and checks for a version
requirement (if any). Returns the name of the loaded module
if it can be loaded successfully and satisfies any specified version
requirement.

On list context, returns the name of the loaded module
and its version (as reported by C<< $m->VERSION >>).

    ( $m, $v ) = try_module($spec);
    ( $m, $v ) = try_module($spec, \%opts);

These options are currently available:

=over 4

=item require

    require => 1    # default
    require => 0
    require => sub { my ($m, @v) = @_; ... }

Controls whether the specified module should be C<require>d or not.
It can be given as a non-subroutine value, which gets
interpreted as a boolean: true means that the module
should be loaded with C<require> and false means
that no attempt should be made to load it.
This option can also be specified as a subroutine which gets
passed the module name and version requirement (if any)
and which should return true if the module should be loaded
with C<require> or false otherwise.

=back

=head1 CAVEATS

=over 4

=item *

Single quotes (C<'>) are not accepted as package separators.

=item *

Exceptions are not thrown from the perspective of the caller.

=back

=head1 SEE ALSO

L<Module::Runtime>

=cut
