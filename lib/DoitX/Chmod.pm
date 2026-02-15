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

package DoitX::Chmod;

use strict;
use warnings;
our $VERSION = '0.01';

use Doit::Log;

use File::chmod ();

sub new { bless {}, shift }
sub functions { qw(symchmod lschmod) }

sub _anychmod {
    my($chmod_type, $doit, @args) = @_;
    my %options; if (@args && ref $args[0] eq 'HASH') { %options = %{ shift @args } }
    my($nonraw_mode, @files) = @args;

    my $funcname = "File::chmod::get".$chmod_type;
    my $func = \&{$funcname};
    my @rawmodes = $func->($nonraw_mode, @files);
    error "Unexpected: number of modes returned by $funcname does not match number of files" if @rawmodes != @files;
    my $changes = 0;
    for my $i (0 .. $#files) {
	$changes += $doit->chmod(\%options, $rawmodes[$i], $files[$i]);
    }
    $changes;
}

sub symchmod { _anychmod('symchmod', @_) }
sub lschmod  { _anychmod('lschmod',  @_) }

1;

__END__
