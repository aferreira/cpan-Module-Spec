
use Test::More 0.88;
use zim 'Module::Spec::V1' => qw(need_module try_module);

use lib qw(t/lib);

{
    my $m = need_module('Foo');
    is $m, 'Foo';
}
{
    my $m = need_module('Foo~0.1.2');
    is $m, 'Foo';
}
{
    my $m = need_module('Foo~0.1.0');
    is $m, 'Foo';
}
{
    my ( $m, $v ) = need_module('Foo');
    is $m, 'Foo';
    is $v, Foo->VERSION;
}
{
    my ( $m, $v ) = need_module('Foo~0.1.2');
    is $m, 'Foo';
    is $v, Foo->VERSION;
}
{
    my ( $m, $v ) = need_module('Foo~0.1.0');
    is $m, 'Foo';
    is $v, Foo->VERSION;
}
{
    my $m = eval { need_module('Foo~0.2.0'); };
    ok !$m;
}

done_testing;
