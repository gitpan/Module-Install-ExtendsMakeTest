package t::Util;

use strict;
use warnings;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;
use File::Basename qw/dirname/;
use Cwd;
use Config;
use base qw(Exporter);

use constant DMAKE => $^O eq 'MSWin32' && $Config{make} eq 'dmake';
use constant MAKE  => $Config{make} || 'make';

our @EXPORT = qw/find_make_test_command unpack_tree build run_make DMAKE/;

sub find_make_test_command {
    my ($fh, @target) = @_;
    my $target = +{ map { $_ => 1 } @target, qw(test test_dynamic) };
    
    my $cwd = getcwd;
    my $tmpdir = tempdir CLEANUP => 1;
    
    chdir $tmpdir or die $!;
    
    unpack_tree($fh);
    
    my $make_test_commands = eval {
        build($cwd);

        my $commands = {};
        open my $fh, '<', 'Makefile' or die "Cannot open 'Makefile' for reading: $!";
        my $regex = _regex(keys %$target);
        while (<$fh>) {
            next unless /^($regex) :: (?:pure_all|$regex)/;
            $commands->{$1} = scalar <$fh>;
            delete $target->{$1};
            my @target = keys %$target;
            last unless @target;
            $regex = _regex(@target);
        }
        return $commands;
    };
    chdir $cwd or die $!;
    
    die $@ if $@;
    
    return $make_test_commands;
}

sub build {
    my $distdir = shift;
    die "Makefile.PL not found" unless -f 'Makefile.PL';
    _addinc("$distdir/blib/lib");
    run_cmd(qq{$^X Makefile.PL "$distdir/lib"});
    run_make();
}

sub run_cmd {
    my ($cmd) = @_;
    my $result = `$cmd`;
    die "$cmd failed ($result)" if $?;
    return $result;
}

sub run_make {
    run_cmd(join ' ', MAKE, @_);
}

sub _parse_data {
    my $fh = shift;
    my ($data, $path);
    while (<$fh>) {
        if (/^\@\@/) {
            ($path) = $_ =~ /^\@\@ (.*)/;
            next;
        }
        $data->{$path} .= $_;
    }
    close $fh;
    return $data;
}

sub unpack_tree {
    my $data = _parse_data(shift);

    for my $path (keys %$data) {
        my $dir = dirname($path);
        unless (-e $dir) {
            mkpath($dir) or die "Cannot mkpath '$dir': $!";
        }
        
        my $content = $data->{$path};
        open my $out, '>', $path or die "Cannot open '$path' for writing: $!";
        print $out $content;
        close $out;
    }
}

sub _addinc {
    my ($path) = @_;
    my $file = 'Makefile.PL';
    open my $fh, '<', $file or die $!;
    my $data = do { local $/; <$fh> };
    close $fh;
    open $fh, '>', $file or die $!;
    print $fh "use lib qw($path);\n";
    print $fh $data;
    close $fh;
}

sub _regex {
    my @target = @_;
    my $regex = join '|', @target;
    return qr/$regex/;
}

1;
__END__
