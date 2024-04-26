use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Snap');

ok defined($d->can('snap_install')), 'snap_install imported';
ok defined($d->can('snap_uninstall')), 'snap_uninstall imported';
