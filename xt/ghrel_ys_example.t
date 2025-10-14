use Test::More;
use Doit;
use File::Temp 'tempdir';
use File::Spec;

plan skip_all => "Author tests only" unless $ENV{DOIT_AUTHOR_TESTS};

my $d = Doit->init;
$d->add_component('DoitX::Ghrel');

my $dest_dir = tempdir(CLEANUP => 1);

my $app            = 'ys';
my $gh_repo        = 'yaml/yamlscript';
my $wanted_version = '0.1.96';

$d->ghrel_install(
    name    => $app,
    gh_repo => $gh_repo,
    version => $wanted_version,
    dest_dir => $dest_dir,
    installed_version_code => sub {
        my(%opts) = @_;
        my($version) = `$opts{path} --version` =~ m{([0-9.]+)$};
        $version;
    },
    download_url_code => sub {
        my(%opts) = @_;
        "$opts{version}/ys-$opts{version}-linux-x64.tar.xz";
    },
);

my $installed_path = File::Spec->catfile($dest_dir, $app);
ok -x $installed_path, "Binary is installed and executable";
my $output = qx{$installed_path --version};
like $output, qr/\Q$wanted_version\E/, "Correct version is installed";

done_testing;