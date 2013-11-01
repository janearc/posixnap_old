#!/usr/bin/perl -w

BEGIN { $|++; print "1..13\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $c, $n1, $n2 );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Graph::Node } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Graph::Container } ? 1 : 0, $i++ );
test ( $c = PuzzleSolver::Graph::Container -> new(), $i++ );
test ( $n1 = PuzzleSolver::Graph::Node -> new( serial => 1 ), $i++ );
test ( $n2 = PuzzleSolver::Graph::Node -> new( serial => 2 ), $i++ );
test ( $n1 -> con( node => $n2, weight => 4 ), $i++ );
test ( $n1 -> con( node => $n1 ), $i++ );
test ( $c -> add( $n1 ), $i++ );
test ( $c -> add( $n2 ), $i++ );
test ( $c -> node(0) -> is_equal( $n1 ), $i++ );
test ( $c -> node(1) -> is_equal( $n2 ), $i++ );
test ( @{ $c -> nodes() } == 2, $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
