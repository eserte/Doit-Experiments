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
our $VERSION = '0.002';

use File::Basename 'basename';

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
    my $check_github_releases  = delete $opts{check_github_releases};
    error 'Unhandled options: ' . join(' ', %opts) if %opts;

    if ($check_github_releases) {
	$d->ghrel_check($gh_repo, "v$version");
    }
    my $path = "/usr/local/bin/$name"; # make configurable?
    my $download_url = $download_url_code->(
        name    => $name,
        version => $version,
    );
    if ($download_url !~ m{^https?}) {
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
        my $downloaded_file = "$ENV{HOME}/Downloads/$base";
        $d->lwp_mirror($download_url, $downloaded_file, refresh => 'always');
        my $sudo = _get_sudo($d);
        my $binary;
        if ($extract_code) {
            $binary = $extract_code->(
                downloaded_file => $downloaded_file,
            );
        } else {
            $binary = $downloaded_file;
        }
        $sudo->copy("$binary", $path); # $binary could be a File::Temp object, force it into a filename
        $sudo->chmod(0755, $path);
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
        warning "$repo has $latest_version available, this script requires only $currently_wanted_version";
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
