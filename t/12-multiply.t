# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 12-multiply.t'
use 5.010001;
use Test::More tests => 3;

use Math::Utils qw(:polynomial);
use strict;
use warnings;

#
# returns 0 (equal) or 1 (not equal). There's no -1 value, unlike other cmp functions.
#
sub polycmp
{
	my($p_ref1, $p_ref2) = @_;

	my @polynomial1 = @$p_ref1;
	my @polynomial2 = @$p_ref2;

	return 1 if (scalar @polynomial1 != scalar @polynomial2);

	foreach my $c1 (@polynomial1)
	{
		my $c2 = shift @polynomial2;
		return 1 if ($c1 != $c2);
	}

	return 0;
}



#
# Groups of three: two multipliers and the answer.
#
my @case0 = (
	[
		[9, -8, 4],
		[10, 3, -1, -10, -3, 1],
		[90, -53, 7, -70, 49, -7, -20, 4],
	],
	[
		[1, 4, 8, 4, 1],
		[1, -4, 8, -4, 1],
		[1, 0, 0, 0, 34, 0, 0, 0, 1],
	],
	[
		[1, 3, 3, 1],
		[3],
		[3, 9, 9, 3],
	]
);

foreach my $cref (@case0)
{
	my($n1_ref, $n2_ref, $m_ref) = @$cref;

	my($r) = pl_mult($n1_ref, $n2_ref);

	my @n1 = @$n1_ref;
	my @n2 = @$n2_ref;
	my @ans = @$r;

	ok((polycmp($m_ref, $r) == 0),
		" [ " . join(", ", @n1) . " ] *" .
		" [ " . join(", ", @n2) . " ] returns\n" .
		" [ " . join(", ", @ans) . " ]\n"
	);
}

1;
