use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Sudoers');

ok defined($d->can('sudoers_install')), 'sudoers_install imported';
