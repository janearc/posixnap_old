#!/usr/bin/perl -w

BEGIN { $|++; print "1..23\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $p1, $p2, $s1, $bounds );

$i = 2;

print "ok 1\n";

# load modules
test ( eval { require PuzzleSolver::Geometry::Shape } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Geometry::Line } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Geometry::Point } ? 1 : 0, $i++ );
# create shape
test ( $s1 = PuzzleSolver::Geometry::Shape -> new(), $i++ );
# test equality
test ( $s1 -> is_equal( $s1 ), $i++ );
# create points and use them to change shape
test ( $p1 = PuzzleSolver::Geometry::Point -> new( x => 1, y => 1 ), $i++ );
test ( $p2 = PuzzleSolver::Geometry::Point -> new( x => 0, y => 0 ), $i++ );
test ( $s1 -> lines(
    PuzzleSolver::Geometry::Line -> new(),
    PuzzleSolver::Geometry::Line -> new(
        p1 => $p1, p2 => $p2
    ) ), $i++ );
# test inequality
test ( (! $s1 -> is_equal( PuzzleSolver::Geometry::Shape -> new() ) ), $i++ );
# test bounds method
test ( $bounds = $s1 -> bounds(), $i++ );
test ( $bounds -> [0] -> is_equal( $p2 ), $i++ );
test ( $bounds -> [1] -> is_equal( $p1 ), $i++ );
# test contains method
test ( $s1 = PuzzleSolver::Geometry::Shape -> new(), $i++ );
test ( $p1 = PuzzleSolver::Geometry::Point -> new( x => 0.5, y => 0.5 ), $i++ );
test ( $s1 -> contains( $p1 ), $i++ );
test ( $p1 = PuzzleSolver::Geometry::Point -> new( x => 1.5, y => 1.5 ), $i++ );
test ( (! $s1 -> contains( $p1 ) ), $i++ );
# area tests
test ( $s1 -> area() == 1, $i++ );
test ( $s1 = PuzzleSolver::Geometry::Shape -> new(
    points => [
        PuzzleSolver::Geometry::Point -> new(),
        PuzzleSolver::Geometry::Point -> new(
            x => 0, y => 4 ),
        PuzzleSolver::Geometry::Point -> new(
            x => 4, y => 0 ),
    ] ), $i++ );
test ( $s1 -> area() == -8, $i++ );
test ( $s1 = PuzzleSolver::Geometry::Shape -> new(
    lines => [
        PuzzleSolver::Geometry::Line -> new(
            p1 => PuzzleSolver::Geometry::Point -> new(
                x => 0, y => 0 ),
            p2 => PuzzleSolver::Geometry::Point -> new(
                x => 1, y => 1 ) ),
        PuzzleSolver::Geometry::Line -> new(
            p1 => PuzzleSolver::Geometry::Point -> new(
                x => 1, y => 1 ),
            p2 => PuzzleSolver::Geometry::Point -> new(
                x => 1, y => 2 ) ),
        PuzzleSolver::Geometry::Line -> new(
            p1 => PuzzleSolver::Geometry::Point -> new(
                x => 1, y => 2 ),
            p2 => PuzzleSolver::Geometry::Point -> new(
                x => 0, y => 1 ) ),
        PuzzleSolver::Geometry::Line -> new(
            p1 => PuzzleSolver::Geometry::Point -> new(
                x => 0, y => 1 ),
            p2 => PuzzleSolver::Geometry::Point -> new(
                x => 0, y => 0 ) ),
    ] ), $i++ );
test ( $s1 -> area() == 1, $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
