package DoitX::Fileutil;

use strict;
use warnings;
our $VERSION = '0.001';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(unless_file_matches) }

sub unless_file_matches {
    my($doit, $code, $file, $hexdigest) = @_;
    error "Please define code subroutine" if !defined $code || ref $code ne 'CODE';
    error "Please define file" if !defined $file;
    error "Please define hexdigest" if !defined $hexdigest;
    error "Wrong format for hexdigest (must be 32 hex digits)" if $hexdigest !~ /^[a-fA-F0-9]{32}$/;

    my $run_code;
    if (!-e $file) {
        $run_code = 1;
    } else {
        if (!open my $fh, $file) {
            warning "File '$file' exists, but cannot be opened ($!). Run code block anyway";
            $run_code = 1;
        } else {
            require Digest::MD5;
            my $md5ctx = Digest::MD5->new;
            local $/ = \4096;
            while(<$fh>) {
                $md5ctx->add($_);
            }
            if (lc $md5ctx->hexdigest ne lc $hexdigest) {
                $run_code = 1;
            }
        }
    }
    if ($run_code) {
        $code->($file);
    } else {
        0;
    }
}

1;

__END__
