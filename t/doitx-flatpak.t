use strict;
use warnings;
use Test::More;
use Doit;

# Use the hack to correctly set dry-run mode
my $d = do {
    local @ARGV = ('--dry-run');
    Doit->init;
};

$d->add_component('DoitX::Flatpak');

ok defined($d->can('flatpak_install')), 'flatpak_install imported';
ok defined($d->can('flatpak_uninstall')), 'flatpak_uninstall imported';

# Skip further tests if flatpak is not available
if (!$d->which('flatpak')) {
    diag "flatpak binary not found, skipping callable tests";
    done_testing();
    exit;
}

# Syntax checks for various call signatures
# Since we are in dry-run mode and we use eval, these should not
# try to change the system state even if ensure returns 0.
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

done_testing();
