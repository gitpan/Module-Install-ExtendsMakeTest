use strict;
use warnings;
use lib 't/lib';

use Test::More;
use t::Util;

ok my $cmd = find_make_test_command(*DATA, 'extends_test'), 'find make test command';
like $cmd->{extends_test}, qr{do './tool/bar.pl'}, 'find after run scripts';

done_testing;

__DATA__
@@ Makefile.PL
use inc::Module::Install;

name 'MyModule';
all_from 'lib/MyModule.pm';

tests 't/*.t';

extends_make_test(
    after_run_scripts => './tool/bar.pl',
    target => 'extends_test',
);

auto_include;
WriteAll;
@@ lib/MyModule.pm
package MyModule;
use 5.006;
our $VERSION = '0.1';
1;
__END__
=pod

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
