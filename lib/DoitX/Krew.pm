# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2024 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# WWW:  https://github.com/eserte/Doit-Experiments
#

package DoitX::Krew;

use strict;
use warnings;
our $VERSION = '0.001';

use Doit::Log;
use Doit::Util qw(in_directory);

use File::Temp qw(tempdir);

sub new { bless {}, shift }
sub functions { qw(krew_install_krew krew_install_plugin) }

sub add_components { qw(lwp) }

# Note: PATH must be added manually, see installation notice
sub krew_install_krew {
    my($d) = @_;

    if (-e "$ENV{HOME}/.krew/bin/kubectl-krew") {
	return 0;
    }

    my $os = $^O;

    if ($os ne 'darwin' && $os ne 'linux') {
	error "Only support for darwin or linux available";
    }

    my $dir = tempdir("DoitX-Krew-XXXXXXXX", TMPDIR => 1, CLEAN => 1);

    chomp(my $arch = $d->info_qx({quiet=>1}, 'uname', '-m'));
    $arch =~ s/x86_64/amd64/;
    $arch =~ s/(arm)(64)?.*/arm/;
    $arch =~ s/aarch64$/arm64/;

    in_directory {
	my $krew = "krew-${os}_${arch}";
	my $url = "https://github.com/kubernetes-sigs/krew/releases/latest/download/$krew.tar.gz";
	$d->lwp_mirror($url, "$krew.tar.gz");
	$d->system('tar', 'zxvf', "$krew.tar.gz");
	$d->system("./$krew", "install", "krew");
    } $dir;

    1;
}

sub krew_install_plugin {
    my($d, $plugin, @rest) = @_;
    error "Please specify plugin to install" if !$plugin;
    error "Currently allows installation of one plugin only" if @rest;

    my $list = $d->info_open3({quiet => 1}, qw(kubectl krew list));
    for my $line (split /\n/, $list) {
	next if $line =~ /^PLUGIN\s+VERSION/;
	my($installed_plugin,$installed_version) = split /\s+/, $line, 2;
	if ($plugin eq $installed_plugin) {
	    return 0;
	}
    }

    $d->system(qw(kubectl krew update));
    $d->system(qw(kubectl krew install), $plugin);

    1;
}

1;

__END__
