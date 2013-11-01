#!/usr/bin/perl -w

BEGIN { $|++; print "1..26\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $p1, $p2, $s1, $s2 );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Snafooz::Piece } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Snafooz::Side } ? 1 : 0, $i++ );
test ( $s1 = [
    PuzzleSolver::Snafooz::Side -> new(side=>"101010"),
    PuzzleSolver::Snafooz::Side -> new(side=>"001011"),
    PuzzleSolver::Snafooz::Side -> new(side=>"101011"),
    PuzzleSolver::Snafooz::Side -> new(side=>"101011"),
    ], $i++ );
test ( $s2 = [
    PuzzleSolver::Snafooz::Side -> new(side=>"101010"),
    PuzzleSolver::Snafooz::Side -> new(side=>"011011"),
    PuzzleSolver::Snafooz::Side -> new(side=>"110110"),
    PuzzleSolver::Snafooz::Side -> new(side=>"001011"),
    ], $i++ );
test ( $p1 = PuzzleSolver::Snafooz::Piece -> new(sides=>$s1,serial=>1), $i++ );
test ( $p2 = PuzzleSolver::Snafooz::Piece -> new(sides=>$s2), $i++ );
test ( $p1 -> serial() == 1, $i++ );
test ( $p2 -> serial() != 1, $i++ );
test ( $p2 -> serial(2), $i++ );
test ( $p2 -> serial() == 2, $i++ );
test ( (! $p1 -> is_equal( $p2 ) ), $i++ );
test ( $p1 -> is_equal( $p1 ), $i++ );
test ( @{ $p1 -> fit( $p2 ) } == 2, $i++ );
test ( $p1 -> fit( $p2 ) -> [0] -> [0] -> is_equal( $p2 -> side(0) ), $i++ );
test ( $p1 -> fit( $p2 ) -> [1] -> [0] -> is_equal( $p2 -> side(3) ), $i++ );
test ( (! defined $p1 -> reverse_fit( $p2 ) -> [0] ), $i++ );
test ( $p2 -> rotate(), $i++ );
test ( $p1 -> fit( $p2 ) -> [0] -> [0] -> is_equal( $p2 -> side(1) ), $i++ );
test ( defined $p2 -> side(0) -> is_equal( $s2 -> [3] ), $i++ );
test ( $p1 -> side(0) -> connect( $p2 -> side(1) ), $i++ );
test ( $p1 -> side(0) -> connect() -> is_equal( $p2 -> side(1) ), $i++ );
test ( $p1 -> break_connections(), $i++ );
test ( (! defined $p1 -> side(0) -> connect() ), $i++ );
test ( $p1 -> rev(), $i++ );
test ( $p1 -> side(0) -> is_equal(
    PuzzleSolver::Snafooz::Side -> new(side=>"110101") ), $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
