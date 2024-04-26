use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Ghrel');

ok defined($d->can('ghrel_install')), 'ghrel_install imported';
ok defined($d->can('ghrel_check')), 'ghrel_check imported';
