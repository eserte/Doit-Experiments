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

package DoitX::Ft;

use strict;
use warnings;
our $VERSION = '0.001';

use Doit::Log;

our %filetests = qw(
    r readable
    w writable
    x executable
    o owned
    R readable_real
    W writable_real
    X executable_real
    O owned_real
    e exists
    z empty
    s size
    f is_file
    d is_directory
    l is_symlink
    p is_pipe
    S is_socket
    b is_block
    c is_character
    t has_tty
    u has_setuid
    g has_setgid
    k has_sticky
    T is_text
    B is_binary
    M modification_days
    A access_days
    C change_days
);

sub new { bless {}, shift }
sub functions {
    map { ("ft_$_", "ft_$filetests{$_}") } sort keys %filetests;
}

for my $short_ft (sort keys %filetests) {
    my $short_func = "ft_$short_ft";
    my $long_func  = "ft_" . $filetests{$short_ft};
    no strict 'refs';
    my $code = q<sub {
	my $self = shift;
	my $file = shift;
	if (!defined $file) {
	    error "Please specify a file";
	}
	if (@_) {
	    error "Please specify only one file";
	}
	> . "-$short_ft" . q< $file;
    }>;
    *{$short_func} = *{$long_func} = eval $code;
    if ($@) {
	error "FATAL ERROR: Can't create function for -$short_ft.\nCode: $code.\nError: $@";
    }
}

1;
