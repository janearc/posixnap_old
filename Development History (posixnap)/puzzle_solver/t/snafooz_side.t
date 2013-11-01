#!/usr/bin/perl -w

BEGIN { $|++; print "1..18\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $s1, $s2 );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Snafooz::Side } ? 1 : 0, $i++ );
test ( $s1 = PuzzleSolver::Snafooz::Side -> new(
    side => "010101", serial => 1 ), $i++ );
test ( $s2 = PuzzleSolver::Snafooz::Side -> new(
    side => "1 0 1 0 1 0" ),  $i++ );
test ( $s1 -> serial() == 1, $i++ );
test ( $s2 -> serial() != 1 , $i++ );
test ( $s2 -> serial( 2 ), $i++ );
test ( $s2 -> serial() == 2, $i++ );
test ( $s1 -> fit( $s2 ), $i++ );
test ( (! $s1 -> reverse_fit( $s2 ) ), $i++ );
test ( (! $s1 -> is_equal( $s2 ) ), $i++ );
test ( $s1 -> is_equal( $s1 ), $i++ );
test ( $s1 -> connect( $s2 ), $i++ );
test ( $s1 -> connect() -> is_equal( $s2 ), $i++ );
test ( $s1 -> break_connection(), $i++ );
test ( (! defined $s1 -> connect() ), $i++ );
test ( $s1 -> rev(), $i++ );
test ( $s1 -> is_equal( $s2 ), $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
