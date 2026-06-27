use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
# Set dry-run to prevent accidental changes
$d->{dry_run} = 1;
$d->add_component('DoitX::Flatpak');

ok defined($d->can('flatpak_install')), 'flatpak_install imported';
ok defined($d->can('flatpak_uninstall')), 'flatpak_uninstall imported';

# Syntax checks for various call signatures
# These should pass as long as they don't die
eval { $d->flatpak_install('org.gimp.GIMP') };
ok !$@, 'flatpak_install($id) callable' or diag $@;

eval { $d->flatpak_install('org.gimp.GIMP', { user => 1 }) };
ok !$@, 'flatpak_install($id, \%opts) callable' or diag $@;

eval { $d->flatpak_install('flathub', 'org.gimp.GIMP') };
ok !$@, 'flatpak_install($remote, $id) callable' or diag $@;

eval { $d->flatpak_install('flathub', 'org.gimp.GIMP', { user => 1 }) };
ok !$@, 'flatpak_install($remote, $id, \%opts) callable' or diag $@;

eval { $d->flatpak_uninstall('org.gimp.GIMP') };
ok !$@, 'flatpak_uninstall($id) callable' or diag $@;

eval { $d->flatpak_uninstall('flathub', 'org.gimp.GIMP') };
ok !$@, 'flatpak_uninstall($remote, $id) callable' or diag $@;

pass 'Basic registration and syntax check complete';
