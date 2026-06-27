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
our $VERSION = '0.02';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(flatpak_install flatpak_uninstall flatpak_remote_add) }

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
    $opts = {} if !defined $opts;
    my $is_user = $opts->{user};
    my $scope_arg = $is_user ? '--user' : '--system';

    my $id;
    if (defined $package_or_file && $package_or_file =~ /\.flatpak$/ && -f $package_or_file) {
        # Try to get the application ID from the bundle file
        $id = eval {
            my $info = $d->info_qx({quiet => 1}, 'flatpak', 'info', '--columns=application', $package_or_file);
            if (defined $info) {
                chomp $info;
                $info =~ s/^\s+//;
                $info =~ s/\s+$//;
            }
            $info;
        };
    } else {
        $id = $package_or_file;
    }

    $d->guarded_step(
        "install flatpak " . (defined $id ? $id : (defined $package_or_file ? $package_or_file : "")) . (defined $remote && $remote ne '' ? " from $remote" : ""),
        ensure => sub {
            return 0 if !defined $id || $id eq ''; # Can't check if we don't know the ID
            my $list = eval {
                $d->info_qx({quiet => 1}, 'flatpak', 'list', $scope_arg, '--columns=application,origin', '--no-headings');
            };
            return 0 if $@ || !defined $list;
            my @lines = split /\n/, $list;
            for my $line (@lines) {
                my($inst_id, $origin) = split ' ', $line;
                if (defined $inst_id && $inst_id eq $id) {
                    if (defined $remote && $remote ne '') {
                        return 1 if defined $origin && $origin eq $remote;
                        next;
                    }
                    return 1;
                }
            }
            return 0;
        },
        using => sub {
            my @cmd = ('flatpak', 'install', $scope_arg, '--noninteractive', '-y');
            push @cmd, $remote if defined $remote && $remote ne '';
            push @cmd, $package_or_file;
            _get_sudo($d, $is_user)->system(@cmd);
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
    $opts = {} if !defined $opts;
    my $is_user = $opts->{user};
    my $scope_arg = $is_user ? '--user' : '--system';

    $d->guarded_step(
        "uninstall flatpak $id" . (defined $remote && $remote ne '' ? " from $remote" : ""),
        ensure => sub {
            my $list = eval {
                $d->info_qx({quiet => 1}, 'flatpak', 'list', $scope_arg, '--columns=application,origin', '--no-headings');
            };
            return 1 if $@ || !defined $list;
            my @lines = split /\n/, $list;
            for my $line (@lines) {
                my($inst_id, $origin) = split ' ', $line;
                if (defined $inst_id && $inst_id eq $id) {
                    if (defined $remote && $remote ne '') {
                        return 0 if defined $origin && $origin eq $remote;
                        next;
                    }
                    return 0;
                }
            }
            return 1;
        },
        using => sub {
            my $ref = (defined $remote && $remote ne '') ? "$remote:$id" : $id;
            my @cmd = ('flatpak', 'uninstall', $scope_arg, '--noninteractive', '-y', $ref);
            _get_sudo($d, $is_user)->system(@cmd);
        }
    );
}

sub flatpak_remote_add {
    my ($d, $name, $location, $opts) = @_;
    $opts = {} if !defined $opts;
    my $is_user = $opts->{user};
    my $scope_arg = $is_user ? '--user' : '--system';

    $d->guarded_step(
        "add flatpak remote $name",
        ensure => sub {
            my $remotes = eval {
                $d->info_qx({quiet => 1}, 'flatpak', 'remotes', $scope_arg, '--columns=name', '--no-headings');
            };
            return 0 if $@ || !defined $remotes;
            my @names = split /\n/, $remotes;
            for my $n (@names) {
                $n =~ s/^\s+//; $n =~ s/\s+$//;
                return 1 if $n eq $name;
            }
            return 0;
        },
        using => sub {
            my @cmd = ('flatpak', 'remote-add', $scope_arg, '--if-not-exists', $name, $location);
            _get_sudo($d, $is_user)->system(@cmd);
        }
    );
}

sub _get_sudo {
    my($d, $is_user) = @_;
    return $d if $is_user;
    if (!defined $d->{__flatpak_sudo}) {
        $d->{__flatpak_sudo} = ($< == 0 ? $d : $d->do_sudo);
    }
    return $d->{__flatpak_sudo};
}

1;

__END__
