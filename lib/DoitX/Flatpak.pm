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

package DoitX::Flatpak;

use strict;
use warnings;
our $VERSION = '0.002';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(flatpak_install flatpak_uninstall) }

sub add_components { qw(guarded) }

sub flatpak_install {
    my $d = shift;
    my($remote, $package_or_file, $opts);
    if (@_ == 3) {
        ($remote, $package_or_file, $opts) = @_;
    } elsif (@_ == 2) {
        if (ref $_[1] eq 'HASH') {
            ($package_or_file, $opts) = @_;
        } else {
            ($remote, $package_or_file) = @_;
        }
    } else {
        ($package_or_file) = @_;
    }
    $opts ||= {};
    my $is_user = $opts->{user};
    my $scope_arg = $is_user ? '--user' : '--system';

    my $id;
    if ($package_or_file =~ /\.flatpak$/ && -f $package_or_file) {
        # Try to get the application ID from the bundle file
        $id = eval {
            local $SIG{CHLD} = 'DEFAULT';
            my $info = $d->info_qx({quiet => 1}, 'flatpak', 'info', '--columns=application', $package_or_file);
            chomp $info;
            $info;
        };
    } else {
        $id = $package_or_file;
    }

    $d->guarded_step(
        "install flatpak " . ($id || $package_or_file) . ($remote ? " from $remote" : ""),
        ensure => sub {
            return 0 if !$id; # Can't check if we don't know the ID
            my $list = eval {
                local $SIG{CHLD} = 'DEFAULT';
                $d->info_qx({quiet => 1}, 'flatpak', 'list', $scope_arg, '--columns=application');
            };
            return 0 if $@;
            my @installed_ids = split /\n/, $list;
            return (grep { $_ eq $id } @installed_ids) ? 1 : 0;
        },
        using => sub {
            my @cmd = ('flatpak', 'install', $scope_arg, '--noninteractive', '-y');
            push @cmd, $remote if $remote;
            push @cmd, $package_or_file;
            if ($is_user) {
                $d->system(@cmd);
            } else {
                _get_sudo($d)->system(@cmd);
            }
        }
    );
}

sub flatpak_uninstall {
    my $d = shift;
    my($remote, $id, $opts);
    if (@_ == 3) {
        ($remote, $id, $opts) = @_;
    } elsif (@_ == 2) {
        if (ref $_[1] eq 'HASH') {
            ($id, $opts) = @_;
        } else {
            ($remote, $id) = @_;
        }
    } else {
        ($id) = @_;
    }
    $opts ||= {};
    my $is_user = $opts->{user};
    my $scope_arg = $is_user ? '--user' : '--system';

    $d->guarded_step(
        "uninstall flatpak $id" . ($remote ? " from $remote" : ""),
        ensure => sub {
            my $list = eval {
                local $SIG{CHLD} = 'DEFAULT';
                $d->info_qx({quiet => 1}, 'flatpak', 'list', $scope_arg, '--columns=application');
            };
            return 1 if $@;
            my @installed_ids = split /\n/, $list;
            return (grep { $_ eq $id } @installed_ids) ? 0 : 1;
        },
        using => sub {
            my @cmd = ('flatpak', 'uninstall', $scope_arg, '--noninteractive', '-y');
            push @cmd, $id;
            if ($is_user) {
                $d->system(@cmd);
            } else {
                _get_sudo($d)->system(@cmd);
            }
        }
    );
}

sub _get_sudo {
    my $d = shift;
    $d->{__flatpak_sudo} ||= do {
        $< == 0 ? $d : $d->do_sudo;
    };
}

1;

__END__
