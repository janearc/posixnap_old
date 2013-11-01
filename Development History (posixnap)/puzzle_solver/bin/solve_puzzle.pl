#!/usr/bin/perl -w

$|++;

use constant PIECE_DIR => "../example_files/purple_puzzle/";

use strict;
use warnings;
use PuzzleSolver::Snafooz::Solver;
use PuzzleSolver::IO::Read;

print <<EOF;

This program will attempt to solve a simple square Snafooz
puzzle found in "../example_files/purple_puzzle/".

EOF

my $s = PuzzleSolver::Snafooz::Solver -> new();
my $in = PuzzleSolver::IO::Read -> new();

print "reading all pieces from files...";
my @pieces = @{ $in -> read_snafooz_pieces_from_dir( PIECE_DIR() ) };
print "done\n";

print <<EOF;

I will now begin searching for solutions.  This may take
some time because I will try to find 'all' valid solutions.

EOF

print "attempting to solve puzzle...";
$s -> solve( \@pieces );
print "done\n";

print "retrieving solutions...";
my @solutions = @{ $s -> get_solutions() };
print "done\n";

print "\n", scalar @solutions, " were found\n";

print <<EOF;

I will now display the the first solution... it will be in the form:

    Place 4
---------------
| 1 1 0 0 1 1 |
| 1 1 * 1 1 1 |
| 0 * 3 * 1 0 |
| 0 1 * 1 1 0 |
| 1 1 1 1 1 1 |
| 1 1 0 0 1 1 |
---------------

 - The place number represents its location in the solution set.
 - The number within the piece surounded by '*' is the serial
    number of the piece within that solution.

The placements for the solution of the default square puzzle are:
      -----
      | 4 |
  -------------
  | 3 | 0 | 1 |
  -------------
      | 2 |
      -----
      | 5 |
      -----

EOF

print "Press <ENTER> to see the solution...";

{
    my $junk = <>;
}

$s -> display_solution( $solutions[0] );

exit;
