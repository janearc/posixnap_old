#!/usr/bin/perl -w

BEGIN { $|++; print "1..14\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $n1, $n2 );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Graph::Node } ? 1 : 0, $i++ );
test ( $n1 = PuzzleSolver::Graph::Node -> new(), $i++ );
test ( $n2 = PuzzleSolver::Graph::Node -> new( serial => 5 ), $i++ );
test ( $n2 -> serial() == 5, $i++ );
test ( $n1 -> serial() != 5, $i++ );
test ( $n1 -> serial(3), $i++ );
test ( $n1 -> serial() == 3, $i++ );
test ( $n1 -> is_equal( $n1 ), $i++ );
test ( (! $n1 -> is_equal( $n2 ) ), $i++ );
test ( $n1 -> con( node => $n2, weight => 4 ), $i++ );
test ( $n1 -> con( node => $n1 ), $i++ );
test ( @{ $n1 -> connections } == 2, $i++ );
test ( @{ $n2 -> connections } == 0, $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
