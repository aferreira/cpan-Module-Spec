
package Module::Spec;

# ABSTRACT: Load modules based on specifications
use 5.010;

# use strict;
# use warnings;

use Module::Spec::V1 ();

sub new {
    my ( $self, %args ) = @_;

    Module::Spec::V1::croak qq{What version?} unless exists $args{ver};

    my $v = $args{ver};
    unless ( defined $v && $v =~ /\A[0-9]+\z/ ) {
        Module::Spec::V1::croak(qq{Invalid version ($v)}) if defined $v;
        Module::Spec::V1::croak(qq{Undefined version});
    }

    Module::Spec::V1::_require_module( my $m = "Module::Spec::V${v}::OO" );
    return bless {}, $m;
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Module::Spec;

    my $ms = Module::Spec->new(ver => 1);
    $ms->need_module('Mango~2.3');

=cut
