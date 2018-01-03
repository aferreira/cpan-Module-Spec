
package Module::Spec::V1;

# ABSTRACT: Load modules based on specifications V1
use 5.010001;

# use strict;
# use warnings;

our @EXPORT_OK = qw(need_module try_module);

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

# need_module($spec)
sub need_module {
    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    _require_module($m);
    $m->VERSION(@v) if @v;
    return wantarray ? ( $m, $m->VERSION ) : $m;
}

# Diagnostics:
#  Can't locate Foo.pm in @INC (you may need to install the Foo module) (@INC contains:
#  Carp version 2.3 required--this is only version 1.40

sub try_module {
    my ( $m, @v ) = _parse_module_spec( $_[-1] )
      or croak(qq{Can't parse $_[-1]});
    eval {
        _require_module($m);
        $m->VERSION(@v) if @v;
        1;
    }
      or
      return;   # FIXME might ignore and eat non-load/non-version-check errors
    return wantarray ? ( $m, $m->VERSION ) : $m;
}

# TODO need_modules($spec1, $spec1)

# Borrowed from Mojo::Util
sub _class_to_path { join '.', join( '/', split( /::|'/, shift ) ), 'pm' }

sub _require_module { require(&_class_to_path) }

sub croak {
    require Carp;
    no warnings 'redefine';
    *croak = \&Carp::croak;
    goto &croak;
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Module::Spec::V1 ();
    Module::Spec::V1::need_module('Mango~2.3');

=head1 DESCRIPTION

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

L<Module::Spec::V1> implements the following functions.

=head2 need_module

    $module = need_module('SomeModule~2.3');
    $module = need_module( { SomeModule => '2.3' } );
    $module = need_module( [ SomeModule => '2.3' ] );

Loads a module and checks for a version requirement (if any).
Returns the name of the loaded module.

On list context, returns the name of the loaded module
and its version (as reported by C<< $m->VERSION >>).

    ( $m, $v ) = need_module($spec);

=cut

