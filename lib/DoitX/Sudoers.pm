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

package DoitX::Sudoers;

use strict;
use warnings;
our $VERSION = '0.001';

use File::Temp qw(tempfile);

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(sudoers_install) }

sub sudoers_install {
    my($d, $basefile, $contents) = @_;

    my $file = "/etc/sudoers.d/$basefile";

    if (open my $fh, '<', $file) {
	local $/ = undef;
	my $installed_contents = <$fh>;
	return 0 if $contents eq $installed_contents;
    }

    my($tmpfh,$tmpfile) = tempfile("doitx-sudoers-XXXXXXXX", TMPDIR => 1, UNLINK => 1);
    print $tmpfh $contents;
    close $tmpfh or error "Can't write temporary file: $!";

    $d->info_system('visudo', '-c', $tmpfile);

    my $sudo = _get_sudo($d);
    return $sudo->write_binary($file, $contents);
}

sub _get_sudo {
    my $d = shift;
    $d->{__snap_sudo} ||= do {
	$< == 0 ? $d: $d->do_sudo;
    };
}
