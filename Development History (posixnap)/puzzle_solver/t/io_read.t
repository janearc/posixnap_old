#!/usr/bin/perl -w

BEGIN { $|++; print "1..28\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $in, $i, $ps, $ls, $s1, $s2, $p1, $p2, $c, $pieces );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::IO::Read } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Geometry::Shape } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Snafooz::Piece } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Graph::Container } ? 1 : 0, $i++ );
test ( $in = PuzzleSolver::IO::Read -> new(), $i++ );
test ( $ps = $in -> read_points_from_file( "t/files/points.txt" ), $i++ );
test ( $s1 = PuzzleSolver::Geometry::Shape -> new(
    points => $ps ), $i++ );
test ( $s1 -> area() == 3, $i++ );
test ( $ls = $in -> read_lines_from_file( "t/files/lines.txt" ), $i++ );
test ( $s2 = PuzzleSolver::Geometry::Shape -> new(
    lines => $ls ), $i++ );
test ( $s1 -> is_equal( $s2 ), $i++ );
test ( $ls = $in -> read_lines_from_file( "t/files/combo.txt" ), $i++ );
test ( $ps = $in -> read_points_from_file( "t/files/combo.txt" ), $i++ );
test ( $s2 = PuzzleSolver::Geometry::Shape -> new(
    lines => $ls ), $i++ );
test ( scalar @{ $ps } == 3, $i++ );

foreach ( 0 .. 1 ) {
    test ( $s1 -> contains( $ps -> [$_] ) ? 1 : 0, $i++ );
}

test ( (! $s1 -> contains( $ps -> [2] ) ), $i++ );

test ( $p1 = $in -> read_snafooz_piece_from_file( "t/files/piece1.txt" ), $i++ );

test ( $c = $in -> read_node_container_from_file( "t/files/nodes.txt" ), $i++ );
test ( $c -> size() == 6, $i++ );
test ( $c -> node(4) -> serial() == 4, $i++ );
test ( $c -> node(4) -> connections() -> [0] -> {node} -> is_equal(
    $c -> node(1) ), $i++ );

test ( $pieces = $in -> read_snafooz_pieces_from_dir( "t/files/purple_puzzle" ), $i++ );
test ( scalar @{ $pieces } == 6, $i++ );
test ( $pieces -> [0] -> serial() == 0, $i++ );
test ( $pieces -> [5] -> serial() == 5, $i++ );
exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
