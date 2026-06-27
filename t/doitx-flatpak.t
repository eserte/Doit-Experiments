use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Flatpak');

ok defined($d->can('flatpak_install')), 'flatpak_install imported';
ok defined($d->can('flatpak_uninstall')), 'flatpak_uninstall imported';
