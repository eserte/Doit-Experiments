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
{
    local $TODO = "No noop on Windows" if $^O eq 'MSWin32';
    is $r->lschmod("-rwxr-xr-x", "doit-test"), 0; # noop
}
eval { $r->lschmod("-rw-r--r--", "does-not-exist") };
like $@, qr{chmod failed: };
## note: lschmod and symchmod work differently and fail on the first file which cannot be handled
#eval { $r->lschmod("-rw-r--r--", "does-not-exist-1", "does-not-exist-2") };
#like $@, qr{chmod failed on all files: };
#eval { $r->lschmod(0644, "doit-test", "does-not-exist") };
#like $@, qr{\Qchmod failed on some files (1/2): };

{
    local $TODO;
    $TODO = "needs review on Windows" if $^O eq 'MSWin32';
    is $r->symchmod("+x", "doit-test", "doit-test2"), 1; # one change expected
    is $r->symchmod("+x", "doit-test", "doit-test2"), 0; # no change expected
    is $r->symchmod("-x", "doit-test", "doit-test2"), 2; # two changes expected
    is $r->symchmod("-x", "doit-test", "doit-test2"), 0; # no change expected
}


