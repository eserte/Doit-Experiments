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

package DoitX::Ghrel;

use strict;
use warnings;
our $VERSION = '0.004';

use File::Basename 'basename';
use File::Temp 'tempdir';
use File::Spec;

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(ghrel_install ghrel_check) }

sub add_components { qw(lwp) }

# XXX Currently only usable for simple files, no .tar.gz or .deb or so
sub ghrel_install {
    my($d, %opts) = @_;
    my $name                   = delete $opts{name}                   || die 'name is mandatory';
    my $gh_repo                = delete $opts{gh_repo}                || die 'gh_repo is mandatory';
    my $version                = delete $opts{version}                || die 'version is mandatory'; # maybe allow also "latest" or so?
    my $download_url_code      = delete $opts{download_url_code}      || die 'download_url_code_is_mandatory';
    my $extract_code           = delete $opts{extract_code};
    my $installed_version_code = delete $opts{installed_version_code} || sub {
        my(%opts) = @_;
	if ($d->info_qx({quiet=>1}, "$opts{path}", '--version') =~ m{version\s+v(\S+)}) {
	    $1;
	} else {
	    undef;
	}
    };
    my $dest_dir               = delete $opts{dest_dir};
    my $check_github_releases  = delete $opts{check_github_releases};
    error 'Unhandled options: ' . join(' ', %opts) if %opts;

    if ($check_github_releases) {
	$d->ghrel_check($gh_repo, "v$version");
    }
    my $path = File::Spec->catfile($dest_dir || '/usr/local/bin', $name);
    my $download_url = $download_url_code->(
        name    => $name,
        version => $version,
    );
    if ($download_url !~ m{^(?:https?|file)://}) {
        $download_url = "https://github.com/$gh_repo/releases/download/$download_url";
    }
    if (!-x $path || do {
        my $installed_version = $installed_version_code->(
            name => $name,
            path => $path,
        );
        $installed_version ne $version;
    }) {
        my $base = basename($download_url);
        my $downloaded_file = File::Spec->catfile($ENV{HOME}, 'Downloads', $base);
        $d->lwp_mirror($download_url, $downloaded_file, refresh => 'always');
        my $doer = $dest_dir ? $d : _get_sudo($d);
        my $binary;
        if (!$extract_code && $downloaded_file =~ m{\.(tar\.gz|tgz|zip)$}) {
            my $suffix = $1;
            my $td = tempdir("ghrel_install_XXXXXX", CLEANUP => 1);
            if ($suffix eq 'zip') {
                require Archive::Zip;
                open my $fh, '<:raw', $downloaded_file or die "Cannot open $downloaded_file: $!";
                my $zip = Archive::Zip->new;
                $zip->readFromFileHandle($fh) == 0 or die "Error reading zip file: $!";
                my @members = $zip->members;
                if (@members == 1) {
                    $binary = File::Spec->catfile($td, $members[0]->fileName);
                    $zip->extractMember($members[0], $binary) == 0 or die "Error extracting from zip: $!";
                } else {
                    my $zip_dir;
                    for my $member (@members) {
                        if ($member->isDirectory) {
                            if (defined $zip_dir) {
                                die "Multiple directories in zip file";
                            }
                            $zip_dir = $member->fileName;
                        }
                    }
                    if ($zip_dir) {
                        $binary = File::Spec->catfile($td, $name);
                        $zip->extractTree($zip_dir, $td) == 0 or die "Error extracting from zip: $!";
                        my @extracted_files = glob "$td/*";
                        # Heuristic: if there's a single directory, then the binary is probably inside
                        if (@extracted_files == 1 && -d $extracted_files[0]) {
                            $binary = File::Spec->catfile($extracted_files[0], $name);
                        } else {
                            $binary = File::Spec->catfile($td, $name);
                        }
                    } else {
                        $binary = File::Spec->catfile($td, $name);
                        $zip->extractTree('', $td) == 0 or die "Error extracting from zip: $!";
                    }
                    if (!-e $binary) {
                        die "Could not find '$name' in zip file";
                    }
                }
                close $fh;
            } else { # tar.gz, tgz
                require Archive::Tar;
                my $tar = Archive::Tar->new;
                open my $fh, '<:raw', $downloaded_file or die "Cannot open $downloaded_file: $!";
                $tar->read($fh, 1) or die "Error reading tar file: $!";
                close $fh;
                my @members = $tar->list_files;
                if (@members == 1) {
                    $binary = File::Spec->catfile($td, $members[0]);
                    $tar->extract_file($members[0], $binary) or die "Error extracting from tar: $!";
                } else {
                    my($tar_dir) = $members[0] =~ m{^([^/]+/)};
                    if ($tar_dir && (scalar(grep { $_ =~ m{^\Q$tar_dir\E} } @members) == @members)) {
                        $binary = File::Spec->catfile($td, $tar_dir, $name);
                    } else {
                        $binary = File::Spec->catfile($td, $name);
                    }
                    $tar->extract($td) or die "Error extracting from tar: $!";
                    if (!-e $binary) {
                        die "Could not find '$name' in tar file";
                    }
                }
            }
        } elsif ($extract_code) {
            $binary = $extract_code->(
                downloaded_file => $downloaded_file,
		name            => $name,
		version         => $version,
            );
        } else {
            $binary = $downloaded_file;
        }
        $doer->copy("$binary", $path); # $binary could be a File::Temp object, force it into a filename
        $doer->chmod(0755, $path);
        1;
    } else {
        0;
    }
}

sub ghrel_check {
    my($d, $repo, $currently_wanted_version) = @_;
    #chomp(my $repo_line = $d->info_qx({quiet => 1}, qw(gh release list -L 1 --exclude-drafts -R), $repo));
    #my($latest_version) = $repo_line =~ m{^(\S+)};
    my $releases = $d->info_qx({quiet => 1}, qw(gh api), "repos/$repo/releases", '--jq', '.[] | select(.draft == false and .prerelease == false) | .tag_name');
    my($latest_version) = $releases =~ m{^(\S+)};
    if ($latest_version eq '') {
        error "Cannot get latest version for $repo";
    }
    if ($latest_version ne $currently_wanted_version) {
	if (($latest_version =~ /^v/ && $currently_wanted_version !~ /^v/) ||
	    ($latest_version !~ /^v/ && $currently_wanted_version =~ /^v/)) {
	    warning qq{Inconsistent handling of leading "v" in versions for "$repo": latest version is "$latest_version", specified wanted version is "$currently_wanted_version"};
	} else {
	    warning "$repo has $latest_version available, this script requires only $currently_wanted_version. Go to https://github.com/$repo/compare/$currently_wanted_version..$latest_version for a comparison.";
	}
	0;
    } else {
	1;
    }
}

sub _get_sudo {
    my $d = shift;
    $d->{__snap_sudo} ||= do {
	$< == 0 ? $d: $d->do_sudo;
    };
}
