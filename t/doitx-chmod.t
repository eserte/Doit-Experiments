use Test::More;
use File::Temp qw(tempdir);

plan skip_all => "requires File::chmod" if !eval { require File::chmod; 1 };
plan 'no_plan';

use Doit;

my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
chdir $tempdir or die "Can't chdir to $tempdir: $!";

my $r = Doit->init;
$r->add_component('DoitX::Chmod');

$r->create_file_if_nonexisting('doit-test');
$r->create_file_if_nonexisting('doit-test2');
is $r->lschmod("-rwxr-xr-x", "doit-test", "doit-test2"), 2; # changes expected
is $r->lschmod("-rw-r--r--", "doit-test2"), 1; # one change expected
is $r->lschmod({quiet => 1}, "-rwxr-xr-x", "doit-test2"), 1;
is $r->lschmod({quiet => 1}, "-rw-r--r--", "doit-test2"), 1;
SKIP: {
    skip "No noop on Windows", 1 if $^O eq 'MSWin32';
    is $r->lschmod("-rwxr-xr-x", "doit-test"), 0; # noop
}
eval { $r->lschmod("-rw-r--r--", "does-not-exist") };
like $@, qr{chmod failed: };
## note: lschmod and symchmod work differently and fail on the first file which cannot be handled
#eval { $r->lschmod("-rw-r--r--", "does-not-exist-1", "does-not-exist-2") };
#like $@, qr{chmod failed on all files: };
#eval { $r->lschmod(0644, "doit-test", "does-not-exist") };
#like $@, qr{\Qchmod failed on some files (1/2): };

SKIP: {
    skip "skipping -x tests Windows", 4 if $^O eq 'MSWin32';
    is $r->symchmod("+x", "doit-test", "doit-test2"), 1; # one change expected
    is $r->symchmod("+x", "doit-test", "doit-test2"), 0; # no change expected
    is $r->symchmod("-x", "doit-test", "doit-test2"), 2; # two changes expected
    is $r->symchmod("-x", "doit-test", "doit-test2"), 0; # no change expected
}

{
    $r->create_file_if_nonexisting('doit-write-test1');
    $r->create_file_if_nonexisting('doit-write-test2');
    $r->chmod(0600, 'doit-write-test1');
    $r->chmod(0400, 'doit-write-test2');
    is $r->symchmod("-w", "doit-write-test1", "doit-write-test2"), 1; # one change expected
    is $r->symchmod("-w", "doit-write-test1", "doit-write-test2"), 0; # no change expected
    is $r->symchmod("+w", "doit-write-test1", "doit-write-test2"), 2; # two changes expected
    is $r->symchmod("+w", "doit-write-test1", "doit-write-test2"), 0; # no change expected
}


