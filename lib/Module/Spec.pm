
package Module::Spec;

# ABSTRACT: Load modules based on specifications
use 5.012;

# use warnings;

BEGIN {
    require Module::Spec::V1;
    *croak = \&Module::Spec::V1::croak;
}

sub new {
    my ( $self, %args ) = @_;

    croak qq{What version?} unless exists $args{ver};

    my $v = $args{ver};
    unless ( defined $v && $v =~ /\A[0-9]+\z/ ) {
        croak qq{Invalid version ($v)} if defined $v;
        croak qq{Undefined version};
    }

    require Module::Spec::OO;
    return bless {}, Module::Spec::OO->create_class($v);
}

1;

=encoding utf8

=head1 SYNOPSIS

    use Module::Spec;

    my $ms = Module::Spec->new(ver => 1);
    $ms->need_module('Mango~2.3');

=head1 DESCRIPTION

B<This is alpha software. The API is likely to change.>

=cut
