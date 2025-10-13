use Test::More;
BEGIN {
    eval "use LWP::UserAgent";
    if ($@) {
        plan skip_all => 'LWP::UserAgent is not installed';
    }
}
use strict;
use warnings;
use Doit;
use File::Temp 'tempdir';
use File::Spec;

my $d = Doit->init;
$d->add_component('DoitX::Ghrel');

my $tempdir = tempdir(CLEANUP => 1);
my $dest_dir = tempdir(CLEANUP => 1);

# Create a dummy binary
my $dummy_binary_name = 'my-app';
my $dummy_binary_path = File::Spec->catfile($tempdir, $dummy_binary_name);
open my $fh, '>', $dummy_binary_path or die "Could not create dummy binary: $!";
print $fh "#!/usr/bin/env perl\nprint 'version v1.0.0'\n";
close $fh;
chmod 0755, $dummy_binary_path;

my ($tar_path, $tar_with_dir_path);
my $has_archive_tar = eval { require Archive::Tar; 1 };

if ($has_archive_tar) {
    # Create a tar.gz archive
    $tar_path = File::Spec->catfile($tempdir, 'my-app.tar.gz');
    my $tar = Archive::Tar->new;
    $tar->add_files($dummy_binary_path);
    $tar->write($tar_path, $Archive::Tar::COMPRESS_GZIP);

    # Create a tar.gz archive with a top-level directory
    $tar_with_dir_path = File::Spec->catfile($tempdir, 'my-app-with-dir.tar.gz');
    my $tar_with_dir = Archive::Tar->new;
    my $dummy_binary_in_dir_name = File::Spec->catfile('my-app-1.0.0', $dummy_binary_name);
    my $dummy_binary_in_dir_path = File::Spec->catfile($tempdir, $dummy_binary_in_dir_name);
    mkdir File::Spec->catfile($tempdir, 'my-app-1.0.0');
    rename $dummy_binary_path, $dummy_binary_in_dir_path;
    $tar_with_dir->add_files($dummy_binary_in_dir_path);
    $tar_with_dir->write($tar_with_dir_path, $Archive::Tar::COMPRESS_GZIP);
    rename $dummy_binary_in_dir_path, $dummy_binary_path; # move it back
}

my ($zip_path, $zip_with_dir_path);
my $has_archive_zip = eval { require Archive::Zip; 1 };

if ($has_archive_zip) {
    # Create a zip archive
    $zip_path = File::Spec->catfile($tempdir, 'my-app.zip');
    my $zip = Archive::Zip->new;
    $zip->addFile($dummy_binary_path, $dummy_binary_name);
    $zip->writeToFileNamed($zip_path);

    # Create a zip archive with a top-level directory
    $zip_with_dir_path = File::Spec->catfile($tempdir, 'my-app-with-dir.zip');
    my $zip_with_dir = Archive::Zip->new;
    $zip_with_dir->addDirectory('my-app-1.0.0/');
    $zip_with_dir->addFile($dummy_binary_path, 'my-app-1.0.0/my-app');
    $zip_with_dir->writeToFileNamed($zip_with_dir_path);
}

$ENV{HOME} = $tempdir; # To control where Downloads go
mkdir File::Spec->catfile($tempdir, 'Downloads');

subtest 'tar.gz extraction' => sub {
    plan skip_all => "Archive::Tar not installed" unless $has_archive_tar;
    my $download_url = "file://$tar_path";
    $d->ghrel_install(
        name => 'my-app',
        gh_repo => 'user/repo',
        version => '1.0.0',
        download_url_code => sub { $download_url },
        dest_dir => $dest_dir,
    );
    my $installed_path = File::Spec->catfile($dest_dir, 'my-app');
    ok -x $installed_path, "Binary is installed and executable";
    my $output = qx{$installed_path};
    is $output, 'version v1.0.0', 'Correct version is installed';
    unlink $installed_path;
};

subtest 'tar.gz with top-level directory extraction' => sub {
    plan skip_all => "Archive::Tar not installed" unless $has_archive_tar;
    my $download_url = "file://$tar_with_dir_path";
    $d->ghrel_install(
        name => 'my-app',
        gh_repo => 'user/repo',
        version => '1.0.0',
        download_url_code => sub { $download_url },
        dest_dir => $dest_dir,
    );
    my $installed_path = File::Spec->catfile($dest_dir, 'my-app');
    ok -x $installed_path, "Binary is installed and executable";
    my $output = qx{$installed_path};
    is $output, 'version v1.0.0', 'Correct version is installed';
    unlink $installed_path;
};

subtest 'zip extraction' => sub {
    plan skip_all => "Archive::Zip not installed" unless $has_archive_zip;
    my $download_url = "file://$zip_path";
    $d->ghrel_install(
        name => 'my-app',
        gh_repo => 'user/repo',
        version => '1.0.0',
        download_url_code => sub { $download_url },
        dest_dir => $dest_dir,
    );
    my $installed_path = File::Spec->catfile($dest_dir, 'my-app');
    ok -x $installed_path, "Binary is installed and executable";
    my $output = qx{$installed_path};
    is $output, 'version v1.0.0', 'Correct version is installed';
    unlink $installed_path;
};

subtest 'zip with top-level directory extraction' => sub {
    plan skip_all => "Archive::Zip not installed" unless $has_archive_zip;
    my $download_url = "file://$zip_with_dir_path";
    $d->ghrel_install(
        name => 'my-app',
        gh_repo => 'user/repo',
        version => '1.0.0',
        download_url_code => sub { $download_url },
        dest_dir => $dest_dir,
    );
    my $installed_path = File::Spec->catfile($dest_dir, 'my-app');
    ok -x $installed_path, "Binary is installed and executable";
    my $output = qx{$installed_path};
    is $output, 'version v1.0.0', 'Correct version is installed';
    unlink $installed_path;
};

done_testing;