#!/usr/bin/perl -w

$|++;

use constant DATAFILE => "../example_files/file1.txt";

use strict;
use warnings;
use PuzzleSolver::IO::Read;
use PuzzleSolver::Geometry::Shape;

print <<EOF;

This program performs containment tests on a shape
and several points.  For more info, read 'README'.

EOF

my $in = PuzzleSolver::IO::Read -> new();

print "reading data from '".DATAFILE."'...";
my $lines = $in -> read_lines_from_file( DATAFILE );
my $points = $in -> read_points_from_file( DATAFILE );
print "done\n";

print "creating shape from data...";
my $shape = PuzzleSolver::Geometry::Shape -> new(
    lines => $lines );
print "done\n";

print <<EOF;

I will now test if the points from the file are
within the bounds of the shape from the same
data file.  Points existing on a line of the
shape are considered to be within the shape.

The expected results are:
    True
    True
    False

('True' when the point is contained, 'False'
when it is not)

NOTE: If the datafile is changed, this information
may be incorrect.

EOF

foreach my $point ( @{ $points } ) {
    print "Point (", $point -> X(),
        ",", $point -> Y(), ")";
    if ( $shape -> contains( $point ) )
        { print " exists within the shape\n" }
    else
        { print " does not exist within the shape\n" }
}

exit;
