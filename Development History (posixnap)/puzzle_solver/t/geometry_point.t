#!/usr/bin/perl -w

BEGIN { $|++; print "1..11\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $p1, $p2 );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Geometry::Point } ? 1 : 0, $i++ );
test ( $p1 = PuzzleSolver::Geometry::Point -> new(), $i++ );
test ( $p1 -> X() == 0, $i++ );
test ( $p1 -> Y() == 0, $i++ );
test ( $p1 -> X(4), $i++ );
test ( $p1 -> Y(-3.1415), $i++ );
test ( $p1 -> X() == 4, $i++ );
test ( $p1 -> Y() == -3.1415, $i++ );
test ( $p2 = PuzzleSolver::Geometry::Point -> new( x => 4, y => -3.1415 ), $i++ );
test ( $p1 -> is_equal( $p2 ), $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
