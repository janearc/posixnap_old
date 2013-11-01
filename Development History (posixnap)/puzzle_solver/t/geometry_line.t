#!/usr/bin/perl -w

BEGIN { $|++; print "1..18\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $l1, $l2 );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Geometry::Line } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Geometry::Point } ? 1 : 0, $i++ );
test ( $l1 = PuzzleSolver::Geometry::Line -> new(), $i++ );
test ( $l1 -> slope == 1, $i++ );
test ( $l1 -> p1() -> is_equal( PuzzleSolver::Geometry::Point -> new() ), $i++ );
test ( $l1 -> p1( PuzzleSolver::Geometry::Point -> new( x => 1, y => 1 ) ), $i++ );
test ( $l1 -> p1() -> is_equal( $l1 -> p2() ), $i++ );
test ( (! $l1 -> is_equal( PuzzleSolver::Geometry::Line -> new() ), $i++ ) );
test ( $l1 -> is_equal( $l1 ), $i++ );
test ( $l1 -> slope == 9999, $i++ );
test ( $l1 = PuzzleSolver::Geometry::Line -> new(
    p1 => PuzzleSolver::Geometry::Point -> new(
        x => 0, y => 0 ),
    p2 => PuzzleSolver::Geometry::Point -> new(
        x => 12, y => 1 ) ), $i++ );
test ( $l2 = PuzzleSolver::Geometry::Line -> new(
    p1 => PuzzleSolver::Geometry::Point -> new(
        x => 1, y => -1 ),
    p2 => PuzzleSolver::Geometry::Point -> new(
        x => 1, y => 13 ) ), $i++ );
test ( $l1 -> intersect( $l2 ), $i++ );
test ( $l2 = PuzzleSolver::Geometry::Line -> new(
    p1 => PuzzleSolver::Geometry::Point -> new(
        x => -1, y => -1 ),
    p2 => PuzzleSolver::Geometry::Point -> new(
        x => 1, y => 13 ) ), $i++ );
test ( (! $l1 -> intersect( $l2 ) ), $i++ );
test ( $l2 = PuzzleSolver::Geometry::Line -> new(
    p1 => PuzzleSolver::Geometry::Point -> new(
        x => 0, y => 0 ),
    p2 => PuzzleSolver::Geometry::Point -> new(
        x => 1, y => 13 ) ), $i++ );
test ( $l1 -> intersect( $l2 ), $i++ );



exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
