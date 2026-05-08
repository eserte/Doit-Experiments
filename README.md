# Doit-Experiments

Various experimental Doit extensions. The rules:
* No stability promises. If you need a specific state of the repository, then clone a specific SHA1.
* No CPAN releases. Only git-cloning is supported. Once a module proves to be useful, it may be removed from this repository and go to CPAN.
* No separation of pod and code. However, if a module gets official, then the pod should be separated into an own file.
* Tests are nice, but not required.

Usage: just git-clone this repository somewhere:

```sh
    cd ~/src
	git clone https://github.com/eserte/Doit-Experiments.git
```

and use it in your Doit-using script:

```perl
    use lib "$ENV{HOME}/src/Doit-Experiments/lib"; # mkdir -p ~/src && git clone https://github.com/eserte/Doit-Experiments ~/src/Doit-Experiments
    use Doit;
	...
	my $doit = Doit->init;
	$doit->add_component('DoitX::Chmod');
    ...
	$doit->symchmod('+x', '/path/to/some/executable-file');
```
