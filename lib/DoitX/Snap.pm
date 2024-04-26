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

package DoitX::Snap;

use strict;
use warnings;
our $VERSION = '0.001';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(snap_install snap_uninstall) }

sub add_components { qw(guarded) }

sub snap_install {
    my($d, $package, $install_options) = @_;
    my $refresh_needed;
    $d->guarded_step(
        "install/refresh snap package $package",
        ensure => sub {
            my %info;
            for my $line (split /\n/, eval { $d->info_qx({quiet=>1}, 'snap', 'info', $package) }) {
                if ($line =~ m{^(\S+):\s*(.*)}) {
                    $info{$1} = $2;
                }
            }
            return 0 if !exists $info{installed};
            if ($install_options) {
                my($channel) = map { /^--channel=(.*)/ ? $1 : () } @$install_options;
                if ($channel && $info{tracking} ne $channel) {
                    info "Currently tracking '$info{tracking}', but requested channel '$channel'";
                    $refresh_needed = 1;
                    return 0;
                }
            }
            return 1;
        },
        using => sub {
            _get_sudo($d)->system('snap', ($refresh_needed ? 'refresh' : 'install'), $package, ($install_options ? @$install_options : ()));
        }
    );
}

sub snap_uninstall {
    my($d, $package) = @_;
    if (-e "/snap/$package") {
        _get_sudo($d)->system('snap', 'remove', $package);
    }
}

sub _get_sudo {
    my $d = shift;
    $d->{__snap_sudo} ||= do {
	$< == 0 ? $d: $d->do_sudo;
    };
}
