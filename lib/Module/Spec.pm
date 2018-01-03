
package Module::Spec;

# ABSTRACT: Load modules based on specifications
use 5.010;

# use strict;
# use warnings;

use Module::Spec::V1 ();

sub new {
    my ( $self, %args ) = @_;
    Module::Spec::V1::croak qq{What version?} unless my $v = $args{ver};
    Module::Spec::V1::_require_module( my $m = "Module::Spec::V$v" );
    return bless {}, $m;
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Module::Spec;

    my $ms = Module::Spec->new(ver => 1);
    $ms->need_module('Mango~2.3');

=cut
