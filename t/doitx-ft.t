use Test::More 'no_plan';

use Doit;

my $d = Doit->init;
$d->add_component('DoitX::Ft');

ok $d->ft_e(__FILE__),        'current test file exists (short)';
ok $d->ft_exists(__FILE__),   'current test file exists (long)';
ok $d->ft_r(__FILE__),        'current test file is readable (short)';
ok $d->ft_readable(__FILE__), 'current test file is readable (long)';

my $file = __FILE__;
for my $ft (sort keys %DoitX::Ft::filetests) {
    my $perl_code = q{-}.$ft.q{ $file};
    my $perl_res = eval $perl_code; die "Code <$perl_code> had problems: $@" if $@;
    my $meth_short = "ft_$ft";
    my $meth_long  = "ft_" . $DoitX::Ft::filetests{$ft};
    my $short_res = $d->$meth_short(__FILE__);
    my $long_res = $d->$meth_short(__FILE__);
    if ($ft =~ m{^[AMC]$}) {
	my $short_delta = abs($short_res-$perl_res);
	my $long_delta = abs($long_res-$perl_res);
	cmp_ok $short_delta, '<=', 1, "delta not too large for $ft (short)";
	cmp_ok $long_delta, '<=', 1, "delta not too large for $ft (long)";
    } else {
	is $short_res, $perl_res, "expected result for $ft (short)";
	is $long_res, $perl_res, "expected result for $ft (long)";
    }
}
