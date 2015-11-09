package Math::Utils;

use 5.010001;
use strict;
use warnings;
use Carp;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	compare => [ qw(generate_fltcmp generate_relational) ],
	fortran => [ qw(log10 copysign) ],
	utility => [ qw(log10 copysign flipsign sign moduli
			rmajor_index cmajor_index
			index_rmajor index_cmajor) ],
	polynomial => [ qw(pl_evaluate pl_dxevaluate
			pl_add pl_sub pl_div pl_mult
			pl_derivative pl_antiderivative) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{compare} },
	@{ $EXPORT_TAGS{utility} },
	@{ $EXPORT_TAGS{polynomial} },
);

our $VERSION = '1.06';

=head1 NAME

Math::Utils - Useful mathematical functions not in Perl.

=head1 SYNOPSIS

    use Math::Utils qw(:utility);    # Useful functions

    #
    # Two uses of sign().
    #
    $d = sign($z - $w);

    @ternaries = sign(@coefficients);

    #
    # $dist will be doubled negative or positive $offest, depending
    # on whether ($from - $to) is positive or negative.
    #
    my $dist = 2 * copysign($offset, $from - $to);

    #
    # Change increment direction if goal is negative.
    #
    $incr = flipsign($incr, $goal);

    #
    # The remainders of n after successive divisions of b, or
    # remainders after a set of divisions.
    #
    @rems = moduli($n, $b);
    @sets = moduli($n, [3, 8]);

    #
    # Base 10 logarithm.
    #
    $scale = log10($pagewidth);

or

    use Math::Utils qw(:compare);    # Make comparison functions with tolerance.

    #
    # Floating point comparison function.
    #
    my $fltcmp = generate_fltmcp(1.0e-7);

    if (&$fltcmp($x0, $x1) < 0)
    {
        add_left($data);
    }
    else
    {
        add_right($data);
    }

    #
    # Or we can create single-operation comparison functions.
    #
    # Here we are only interested in the greater than and less than
    # comparison functions.
    #
    my(undef, undef,
        $approx_gt, undef, $approx_lt) = generate_relational(1.5e-5);

or

    use Math::Utils qw(:polynomial);    # Basic polynomial ops

    #
    # Coefficient lists run from 0th degree upward, left to right.
    #
    my @c1 = (1, 3, 5, 7, 11, 13, 17, 19);
    my @c2 = (1, 3, 1, 7);
    my @c3 = (1, -1, 1)

    my $c_ref = pl_mult(\@c1, \@c2);
    $c_ref = pl_add($c_ref, \@c3);

=head1 EXPORT

All functions can be exported by name, or by using the tag that they're
grouped under.

=cut

=head2 utility tag

Useful, general-purpose functions, including those that originated in
FORTRAN and were implemented in Perl in the module L<Math::Fortran>,
by J. A. R. Williams.

There is a name change -- copysign() was known as sign()
in Math::Fortran.

=head3 sign()

    $s = sign($x);
    @valsigns = sign(@values);

Returns -1 if the argument is negative, 0 if the argument is zero, and 1
if the argument is positive.

In list form it applies the same operation to each member of the list.

=cut

sub sign
{
	return wantarray? map{($_ < 0)? -1: (($_ > 0)? 1: 0)} @_:
		($_[0] < 0)? -1: (($_[0] > 0)? 1: 0);
}

=head3 copysign()

    $ms = copysign($m, $n);
    $s = copysign($x);

Take the sign of the second argument and apply it to the first. Zero
is considered part of the positive signs.

    copysign(-5, 0);  # Returns 5.
    copysign(-5, 7);  # Returns 5.
    copysign(-5, -7); # Returns -5.
    copysign(5, -7);  # Returns -5.

If there is only one argument, return -1 if the argument is negative,
otherwise return 1. For example, copysign(1, -4) and copysign(-4) both
return -1.

=cut

sub copysign
{
	return ($_[1] < 0)? -abs($_[0]): abs($_[0]) if (@_ == 2);
	return ($_[0] < 0)? -1: 1;
}

=head3 flipsign()

    $ms = flipsign($m, $n);

Multiply the signs of the arguments and apply it to the first. As
with copysign(), zero is considered part of the positive signs.

Effectively this means change the sign of the first argument if
the second argument is negative.

    flipsign(-5, 0);  # Returns -5.
    flipsign(-5, 7);  # Returns -5.
    flipsign(-5, -7); # Returns 5.
    flipsign(5, -7);  # Returns -5.

If for some reason flipsign() is called with a single argument,
that argument is returned unchanged.

=cut

sub flipsign
{
	return -$_[0] if (@_ == 2 and $_[1] < 0);
	return $_[0];
}


=head3 log10()

    $xlog10 = log10($x);
    @xlog10 = log10(@x);

Return the log base ten of the argument. A list form of the function
is also provided.

=cut

sub log10
{
	my $log10 = log(10);
	return wantarray? map(log($_)/$log10, @_): log($_[0])/$log10;
}

=head3 moduli()

With a simple divisor, returns the moduli of a number.

    @rems = moduli(29, 3);   # Returns (1, 0, 0, 2)
    @digits = moduli(1899, 10);   # Returns (1, 8, 9, 9)

The remainders are returned in a list from right to left.
This order is convenient for convert-to-base operations.

With an array of divisors, returns the modulus for each
one in the array.

    @coords = moduli(29, [6, 6]);   # Returns (5, 4)
    @coords = moduli(29, [4, 9]);   # Returns (1, 7)
    @coords3 = moduli(87, [8, 8, 3]);   # Returns (7, 2, 1)

    #
    # One hundred pence (before conversion to decimal currency)
    # is 0 pounds, 8 shillings, and 4 pence.
    #
    @dsl = moduli(100, [12, 20, 240]);  # Returns (4, 8, 0)

    #
    # 29 bronze Knuts to a silver Sickle, 17 Sickles to a gold Galleon.
    #
    @ksg = moduli(100, [29, 17, 493]);  # Returns (13, 3, 0)

=cut

sub moduli
{
	my($n, $b) = @_;
	my @coord;
	use integer;

	if (ref $b eq "ARRAY")
	{
		for my $d (@$b)
		{
			push @coord, $n % $d;
			$n /= $d;
		}
		return @coord;
	}
	else
	{
		#
		# It could happen. Someone might type \$x instead of $x.
		#
		$b = $$b if (ref $b eq "SCALAR");
		return ($n) if ($b < 2 or $n < $b);

		for (;;)
		{
			unshift @coord, $n % $b;
			$n /= $b;
			return ($n, @coord) if ($n < $b);
		}
	}
	return ();
}

=head3 cmajor_index()

Returns the memory index of a column-major array. By default, the
array is assumed to be zero-based.

    $idx = cmajor_index([6, 6], [2, 3]);    # Returns 20

In other words, in a 6x6 matrix, with coordinates [0..5, 0..5], then
row 3, column 3, is the 20th by index in memory (or a single list).

It is possible to adjust the coordinates of the zeroth index.
For example, if the array is actually one-based, then in a 6x6 matrix, with
coordinates [1..6, 1..6], then row 2, column 3, is the 13th by index
in memory (or a single list).

    $idx = cmajor_index([6, 6], [2, 3], [1, 1]);    # Returns 13

Obviously, [0, 0] and [1, 1] both map to zero in zero-based and one-based
matrices.

    #
    # Both indexes will be zero.
    #
    $idx0 = cmajor_index([6, 6], [0, 0]);
    $idx1 = cmajor_index([6, 6], [1, 1], [1, 1]);

=cut

sub cmajor_index
{
	my($dimensions, $coordinates, $offset) = @_;
	my(@coord) = @$coordinates;
	my(@dim) = @$dimensions;

	my $nc = $#coord;
	my $nd = $#dim;

	if ($nd != $nc)
	{
		carp "Mis-matched dimensional sizes.";
		return undef;
	}

	if (defined $offset)
	{
		$coord[$_] -= $$offset[$_] for (0..$nd);
	}

	my $idx = 0;
	for my $j (reverse 0..$nd)
	{
		$idx *= $dim[$j];
		$idx += $coord[$j];
	}
	return $idx;
}

=head3 rmajor_index()

Returns the memory index of a row-major array. By default, the
array is assumed to be zero-based.

    $idx = rmajor_index([6, 6], [2, 3]);    # Returns 15

In other words, in a 6x6 matrix, with coordinates [0..5, 0..5], then
row 3, column 3, is the 20th by index in memory (or a single list).

It is possible to adjust the coordinates of the zeroth index.
For example, if the array is actually one-based, then in a 6x6 matrix, with
coordinates [1..6, 1..6], then row 2, column 3, is the 13th by index
in memory (or a single list).

    $idx = rmajor_index([6, 6], [2, 3], [1, 1]);    # Returns 8

Obviously, [0, 0] and [1, 1] both map to zero in zero-based and one-based
matrices.

    #
    # Both indexes will be zero.
    #
    $idx0 = rmajor_index([6, 6], [0, 0]);
    $idx1 = rmajor_index([6, 6], [1, 1], [1, 1]);

=cut

sub rmajor_index
{
	my($dimensions, $coordinates, $offset) = @_;
	my(@coord) = @$coordinates;
	my(@dim) = @$dimensions;

	my $nc = $#coord;
	my $nd = $#dim;

	if ($nd != $nc)
	{
		carp "Mis-matched dimensional sizes.";
		return undef;
	}

	if ($offset)
	{
		$coord[$_] -= $$offset[$_] for (0..$nd);
	}

	my $idx = 0;
	for my $j (0..$nd)
	{
		$idx *= $dim[$j];
		$idx += $coord[$j];
	}
	return $idx;
}

=head3 index_cmajor()

Given the dimensions of a column-major matrix and an index into its memory,
return the coordinates in the matrix.

    $coord = index_cmajor([6, 6], 20 );    # Returns [2, 3]

    $coord = index_cmajor([6, 6], 13, [1, 1]);    # Returns [2, 3]

Zero will map to either [0, 0] or [1, 1] depending upon whether the matrix
is zero-based or one-based.

=cut

sub index_cmajor
{
	my($dimensions, $index, $offset) = @_;
	my @coord = moduli($index, $dimensions);

	if (defined $offset)
	{
		my $n = $#$offset;
		$coord[$_] += $$offset[$_] for (0..$n);
	}

	return [@coord];
}

=head3 index_rmajor()

=cut

sub index_rmajor
{
	my($dimensions, $index, $offset) = @_;
	my @coord = moduli($index, [reverse @$dimensions]);

	if (defined $offset)
	{
		my $n = $#$offset;
		$coord[$_] += $$offset[$_] for (0..$n);
	}

	return [reverse @coord];
}

=head2 compare tag

Create comparison functions for floating point (non-integer) numbers.

Since exact comparisons of floating point numbers tend to be iffy,
the comparison functions use a tolerance chosen by you. You may
then use those functions from then on confident that comparisons
will be consistent.

If you do not provide a tolerance, a default tolerance of 1.49e-8
(approximately the square root of an Intel Pentium's
L<machine epsilon|http://en.wikipedia.org/wiki/Machine_epsilon>)
will be used.

=head3 generate_fltcmp()

Returns a comparison function that will compare values using a tolerance
that you supply. The generated function will return -1 if the first
argument compares as less than the second, 0 if the two arguments
compare as equal, and 1 if the first argument compares as greater than
the second.

    my $fltcmp = generate_fltcmp(1.5e-7);

    my(@xpos) = grep {&$fltcmp($_, 0) == 1} @xvals;

=cut

sub generate_fltcmp
{
	my $tol = $_[0] // 1.49e-8;

	return sub {
		my($x, $y) = @_;
		return 0 if (abs($x - $y) <= $tol);
		return -1 if ($x < $y);
		return 1;
	}
}

=head3 generate_relational()

Returns a list of comparison functions that will compare values using a
tolerance that you supply. The generated functions will be the equivalent
of the equal, not equal, greater than, greater than or equal, less than,
and less than or equal operators.


    my($eq, $ne, $gt, $ge, $lt, $le) = generate_relational(1.5e-7);

    my(@approx_5) = grep {&$eq($_, 5)} @xvals;

Of course, if you were only interested in not equal, you could use:

    my(undef, $ne) = generate_relational(1.5e-7);

    my(@not_around5) = grep {&$ne($_, 5)} @xvals;

Internally, the functions are all created using generate_fltcmp().

=cut

sub generate_relational
{
	my $fltcmp = generate_fltcmp($_[0]);

	#
	# In order: eq, ne, gt, ge, lt, le.
	#
	return (
		sub {return &$fltcmp(@_) == 0;},	# eq
		sub {return &$fltcmp(@_) != 0;},	# ne
		sub {return &$fltcmp(@_) >  0;},	# gt
		sub {return &$fltcmp(@_) >= 0;},	# ge
		sub {return &$fltcmp(@_) <  0;},	# lt
		sub {return &$fltcmp(@_) <= 0;},	# le
	);
}

=head2 polynomial tag

Perform some polynomial operations on plain lists of coefficients.

    #
    # The coefficient lists are presumed to go from low order to high:
    #
    @coefficients = (1, 2, 4, 8);    # 1 + 2x + 4x**2 + 8x**3

In all functions the coeffcient list is passed by reference to the function,
and the functions that return coefficients all return references to a coefficient list.

B<It is assumed that any leading zeros in the coefficient lists have
already been removed before calling these functions, and that any leading
zeros found in the returned lists will be handled by the caller.> This caveat
is particulary important to note in the case of C<pl_div()>.

Although these functions are convenient for simple polynomial operations,
for more advanced polynonial operations L<Math::Polynomial> is recommended.

=head3 pl_evaluate()

    $y = pl_evaluate(\@coefficients, $x);
    @yvalues = pl_evaluate(\@coefficients, \@xvalues);

Returns either a y-value for a corresponding x-value, or a list of
y-values on the polynomial for a corresponding list of x-values,
using Horner's method.

=cut

sub pl_evaluate
{
	my @coefficients = @{$_[0]};
	my $xval_ref = $_[1];

	my @xvalues;

	#
	# It could happen. Someone might type \$x instead of $x.
	#
	@xvalues = (ref $xval_ref eq "ARRAY")? @$xval_ref:
		(((ref $xval_ref eq "SCALAR")? $$xval_ref: $xval_ref));

	#
	# Move the leading coefficient off the polynomial list
	# and use it as our starting value(s).
	#
	my @results = (pop @coefficients) x scalar @xvalues;

	for my $c (reverse @coefficients)
	{
		for my $j (0..$#xvalues)
		{
			$results[$j] = $results[$j] * $xvalues[$j] + $c;
		}
	}

	return wantarray? @results: $results[0];
}

=head3 pl_dxevaluate()

    ($y, $dy, $ddy) = pl_dxevaluate(\@coefficients, $x);

Returns p(x), p'(x), and p"(x) of the polynomial for an
x-value, using Horner's method. Note that unlike C<pl_evaluate()>
above, the function can only use one x-value.

=cut

sub pl_dxevaluate
{
	my($coef_ref, $x) = @_;
	my(@coefficients) = @$coef_ref;
	my $n = $#coefficients;
	my $val = pop @coefficients;
	my $d1val = $val * $n;
	my $d2val = 0;

	#
	# Special case for the linear eq'n (the y = constant eq'n
	# takes care of itself).
	#
	if ($n == 1)
	{
		$d1val = $val;
		$val = $val * $x + $coefficients[0];
	}
	elsif ($n >= 2)
	{
		my $lastn = --$n;
		$d2val = $d1val * $n;

		#
		# Loop through the coefficients, except for
		# the linear and constant terms.
		#
		for my $c (reverse @coefficients[2..$lastn])
		{
			$val = $val * $x + $c;
			$d1val = $d1val * $x + ($c *= $n--);
			$d2val = $d2val * $x + ($c * $n);
		}

		#
		# Handle the last two coefficients.
		#
		$d1val = $d1val * $x + $coefficients[1];
		$val = ($val * $x + $coefficients[1]) * $x + $coefficients[0];
	}

	return ($val, $d1val, $d2val);
}

=head3 pl_add()

    $polyn_ref = pl_add(\@m, \@n);

Add two lists of numbers as though they were polynomial coefficients.

=cut

sub pl_add
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)?
		splice(@bv, scalar @bv + $ldiff, -$ldiff):
		splice(@av, scalar @av - $ldiff, $ldiff);

	unshift @result, map($av[$_] + $bv[$_], 0.. $#av);

	return \@result;
}

=head3 pl_sub()

    $polyn_ref = pl_sub(\@m, \@n);

Subtract the second list of numbers from the first as though they were polynomial coefficients.

=cut

sub pl_sub
{
	my(@av) = @{$_[0]};
	my(@bv) = @{$_[1]};
	my $ldiff = scalar @av - scalar @bv;

	my @result = ($ldiff < 0)?
		map {-$_} splice(@bv, scalar @bv + $ldiff, -$ldiff):
		splice(@av, scalar @av - $ldiff, $ldiff);

	unshift @result, map($av[$_] - $bv[$_], 0.. $#av);

	return \@result;
}

=head3 pl_div()

    ($q_ref, $r_ref) = pl_div(\@numerator, \@divisor);

Synthetic division for polynomials. Divides the first list of coefficients
by the second list.

Returns references to the quotient and the remainder.

Remember to check for leading zeros (which are rightmost in the list) in
the returned values. For example,

    my @n = (4, 12, 9, 3);
    my @d = (1, 3, 3, 1);

    my($q_ref, $r_ref) = pl_div(\@n, \@d);

After division you will have returned C<(3)> as the quotient,
and C<(1, 3, 0)> as the remainder. In general, you will want to remove
the leading zero in the remainder.

=cut

sub pl_div
{
	my @numerator = @{$_[0]};
	my @divisor = @{$_[1]};

	my @quotient;

	my $n_degree = $#numerator;
	my $d_degree = $#divisor;

	#
	# Sanity checks: a numerator less than the divisor
	# is automatically the remainder; and return a pair
	# of undefs if either set of coefficients are
	# empty lists.
	#
	return ([0], \@numerator) if ($n_degree < $d_degree);
	return (undef, undef) if ($d_degree < 0 or $n_degree < 0);

	my $lead_coefficient = $divisor[$#divisor];

	#
	# Perform the synthetic division. The remainder will
	# be what's left in the numerator.
	# (4, 13, 4, -9, 6) / (1, 2) = (4, 5, -6, 3)
	#
	@quotient = reverse map {
		#
		# Get the next term for the quotient. We pop
		# off the lead numerator term, which would become
		# zero due to subtraction anyway.
		#
		my $q = (pop @numerator)/$lead_coefficient;

		for my $k (0..$d_degree - 1)
		{
			$numerator[$#numerator - $k] -= $q * $divisor[$d_degree - $k - 1];
		}

		$q;
	} reverse (0 .. $n_degree - $d_degree);

	return (\@quotient, \@numerator);
}

=head3 pl_mult()

    $m_ref = pl_mult(\@coefficients1, \@coefficients2);

Returns the reference to the product of the two multiplicands.

=cut

sub pl_mult
{
	my($av, $bv) = @_;
	my $a_degree = $#{$av};
	my $b_degree = $#{$bv};

	#
	# Rather than multiplying left to right for each element,
	# sum to each degree of the resulting polynomial (the list
	# after the map block). Still an O(n**2) operation, but
	# we don't need separate storage variables.
	#
	return [ map {
		my $a_idx = ($a_degree > $_)? $_: $a_degree;
		my $b_to = ($b_degree > $_)? $_: $b_degree;
		my $b_from = $_ - $a_idx;

		my $c = $av->[$a_idx] * $bv->[$b_from];

		for my $b_idx ($b_from+1 .. $b_to)
		{
			$c += $av->[--$a_idx] * $bv->[$b_idx];
		}
		$c;
	} (0 .. $a_degree + $b_degree) ];
}

=head3 pl_derivative()

    $poly_ref = pl_derivative(\@coefficients);

Returns the derivative of a polynomial.

=cut

sub pl_derivative
{
	my @coefficients = @{$_[0]};
	my $degree = $#coefficients;

	return [] if ($degree < 1);

	$coefficients[$_] *= $_ for (2..$degree);

	shift @coefficients;
	return \@coefficients;
}

=head3 pl_antiderivative()

    $poly_ref = pl_antiderivative(\@coefficients);

Returns the antiderivative of a polynomial. The constant value is
always set to zero and will need to be changed by the caller if a
different constant is needed.

  my @coefficients = (1, 2, -3, 2);
  my $integral = pl_antiderivative(\@coefficients);

  #
  # Integral needs to be 0 at x = 1.
  #
  my @coeff1 = @{$integral};
  $coeff1[0] = - pl_evaluate($integral, 1);

=cut

sub pl_antiderivative
{
	my @coefficients = @{$_[0]};
	my $degree = scalar @coefficients;

	#
	# Sanity check if its an empty list.
	#
	return [0] if ($degree < 1);

	$coefficients[$_ - 1] /= $_ for (2..$degree);

	unshift @coefficients, 0;
	return \@coefficients;
}

=head1 AUTHOR

John M. Gamble, C<< <jgamble at cpan.org> >>

=head1 SEE ALSO

L<Math::Polynomial> for a complete set of polynomial operations, with the
added convenience that objects bring.

Among its other functions, L<List::Util> has the mathematically useful
functions max(), min(), product(), sum(), and sum0().

L<List::MoreUtils> has the function minmax().

L<Math::Prime::Util> has gcd() and lcm() functions, as well as vecsum(),
vecprod(), vecmin(), and vecmax(), which are like the L<List::Util>
functions but which can force integer use, and when appropriate use
L<Math::BigInt>.

L<Math::VecStat> Likewise has min(), max(), sum() (which can take
as arguments array references as well as arrays), plus maxabs(),
minabs(), sumbyelement(), convolute(), and other functions.

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

This module is on Github at L<https://github.com/jgamble/Math-Utils>.

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Utils/>

=back


=head1 ACKNOWLEDGEMENTS

To J. A. R. Williams who got the ball rolling with L<Math::Fortran>.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 by John M. Gamble

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Math::Utils
