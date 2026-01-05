# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2026 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# WWW:  https://github.com/eserte/Doit-Experiments
#

package DoitX::Checkpoint;

use strict;
use warnings;
our $VERSION = '0.001';
use FindBin;

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(checkpoint) }

sub checkpoint {
    my($doit, $name) = @_;
    error "Please specify checkpoint name" if !defined $name;
    my $checkpoint_dir_basename = $FindBin::RealScript;
    $checkpoint_dir_basename =~ s{/}{_}g; # should not happen, just in case
    my $checkpoint_dir = "$ENV{HOME}/.doit-checkpoints/$checkpoint_dir_basename";
    my $file = "$checkpoint_dir/$name";
    return if -e $file;
    info "Reached checkpoint $name";
    if (!$doit->is_dry_run) {
	$doit->make_path($checkpoint_dir);
	$doit->create_file_if_nonexisting($file);
	error "Stop, please re-run script with --dry-run!";
    } else {
	error "Stop, please try now the real run!";
    }
}

1;

__END__
