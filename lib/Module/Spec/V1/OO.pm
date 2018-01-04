
package Module::Spec::V1::OO;

BEGIN {
    require Module::Spec::V1;
    our @ISA = qw(Module::Spec::V1);
}

use Class::Method::Modifiers 'around';

# Allow certain functions in the base class to act as methods

around [ 'need_module', 'try_module', 'generate_code' ] => sub {
    return $_[0]->( @_[ 2 .. $#_ ] );    # Discard invocant
};

1;
