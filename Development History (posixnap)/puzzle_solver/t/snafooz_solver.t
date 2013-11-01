#!/usr/bin/perl -w

BEGIN { $|++; print "1..50\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $s, $in, $ps, $np, $sols );

$i = 2;

print "ok 1\n";

test ( eval { require PuzzleSolver::Snafooz::Side } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Snafooz::Piece } ? 1 : 0, $i++ );
test ( eval { require PuzzleSolver::Snafooz::Solver } ? 1 : 0, $i++ );
test ( $s = PuzzleSolver::Snafooz::Solver -> new(), $i++ );
test ( eval { require PuzzleSolver::IO::Read } ? 1 : 0, $i++ );
test ( $in = PuzzleSolver::IO::Read -> new(), $i++ );
#test ( $ps = $in -> read_snafooz_pieces_from_dir( "t/files/purple_puzzle" ), $i++ );
test ( $ps = $in -> read_snafooz_pieces_from_dir( "example_files/purple_puzzle" ), $i++ );
test ( $s -> begin_permute( $ps ), $i++ );
test ( $np = scalar @{ $s -> {objects} -> {permut} }, $i++ );
test ( $np == 32, $i++ );
foreach ( 0 .. 31 ) {
    test ( $s -> next_permute(), $i++ );
}
test ( (! defined $s -> next_permute() ), $i++ );
test ( $s -> build_fit_db( $ps ), $i++ );
test ( keys %{ $ps -> [0] -> {objects} -> {fit} } == 4, $i++ );

# XXX: there is a bug in the solver.  it
# must be cleaned before the fit can return the
# correct number, i dont know why yet

# clean the solver
test ( $s = PuzzleSolver::Snafooz::Solver -> new(), $i++ );

test ( $s -> solve( $ps ), $i++ );
test ( $sols = $s -> get_solutions(), $i++ );
test ( @{ $sols } == 16, $i++ );

exit;

sub test {
    print $_[0] ? "" : "not ",
        "ok $_[1]",
        $_[2] ? " $_[2]" : "", "\n";
}
