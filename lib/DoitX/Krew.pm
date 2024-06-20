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

sub krew_install_krew {
    my($d, %opts) = @_;
    my $create_symlink = delete $opts{'create_symlink'};
    die "Unhandled options: " . join(" ", %opts) if %opts;

    if ($d->which('kubectl-krew')) {
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
	_get_sudo($d)->ln_nsf("$ENV{HOME}/.krew/bin/kubectl-krew", "/usr/local/bin/kubectl-krew");
    } $dir;

    1;
}

sub _get_sudo {
    my $d = shift;
    $d->{__krew_sudo} ||= do {
	$< == 0 ? $d: $d->do_sudo;
    };
}

1;

__END__
