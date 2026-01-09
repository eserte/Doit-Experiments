use Test::More 'no_plan';
use File::Temp qw(tempdir);

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Fileutil');

my $test_md5 = 'd8e8fca2dc0f896fd7cb4cb0031ba249'; # "test\n"
my $bla_md5  = '3cd7a0db76ff9dca48979e24c39b408c'; # "bla\n"

my $dir = tempdir(TMPDIR => 1, CLEANUP => 1);

sub write_test ($) {
    my $content = shift;
    $d->write_binary("$dir/test", $content);
}

write_test "test\n";

eval { $d->unless_file_matches };
like $@, qr{Please define code subroutine}, 'error message: 1st arg missing';

eval { $d->unless_file_matches("nocode") };
like $@, qr{Please define code subroutine}, 'error message: 1st arg wrong';

eval { $d->unless_file_matches(sub {}) };
like $@, qr{Please define file}, 'error message: 2nd arg missing';

eval { $d->unless_file_matches(sub {}, "$dir/test") };
like $@, qr{Please define hexdigest}, 'error message: 3rd arg missing';

eval { $d->unless_file_matches(sub {}, "$dir/test", "x") };
like $@, qr{\QWrong format for hexdigest (must be 32 hex digits)}, 'error message: 3rd arg wrong';

{
    my $executed = 0;
    ok !$d->unless_file_matches(sub {
				    $executed = 1;
				    1;
				}, "$dir/test", $test_md5), 'unless_file_matches code block not executed';
    is $executed, 0, 'variable still unchanged';
}

{
    my $executed = 0;
    ok $d->unless_file_matches(sub {
				   write_test "bla\n";
				   $executed = 1;
				   1;
			       }, "$dir/test", $bla_md5), 'unless_file_matches code block executed (different content)';
    is $executed, 1, 'variable changed';
}

{
    my $executed = 0;
    ok !$d->unless_file_matches(sub {
				    $executed = 1;
				    1;
				}, "$dir/test", $bla_md5), 'unless_file_matches code block not executed';
    is $executed, 0, 'variable unchanged';
}

$d->unlink("$dir/test");

{
    my $executed = 0;
    ok $d->unless_file_matches(sub {
				   write_test "bla\n";
				   $executed = 1;
				   1;
			       }, "$dir/test", $bla_md5), 'unless_file_matches code block executed (file does not exist)';
    is $executed, 1, 'variable changed';
}
