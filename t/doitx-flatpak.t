use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Flatpak');

ok defined($d->can('flatpak_install')), 'flatpak_install imported';
ok defined($d->can('flatpak_uninstall')), 'flatpak_uninstall imported';

# Syntax checks for various call signatures
if ($ENV{DOIT_EXTENSIVE_TESTS}) {
    # We don't want to actually run these unless flatpak is available and we are in a safe env
    eval { $d->flatpak_install('org.gimp.GIMP', { dry_run => 1 }) };
    eval { $d->flatpak_install('flathub', 'org.gimp.GIMP', { dry_run => 1 }) };
    eval { $d->flatpak_uninstall('org.gimp.GIMP', { dry_run => 1 }) };
}

pass 'Basic registration and syntax check complete';
