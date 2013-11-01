#!/usr/bin/perl -w

$|++;

use constant PIECE1 => "../example_files/piece1.txt";
use constant PIECE2 => "../example_files/piece2.txt";

use strict;
use warnings;
use PuzzleSolver::Snafooz::Piece;
use PuzzleSolver::Snafooz::Solver;
use PuzzleSolver::IO::Read;

print <<EOF;

This program performs fit tests on two different
Snafooz puzzle pieces.  For more info, read 'README'.

EOF

my $s = PuzzleSolver::Snafooz::Solver -> new();
$s -> {objects} -> {debug} = 1;
my $in = PuzzleSolver::IO::Read -> new();
my @pieces;

print "creating piece 1 from '".PIECE1."'...";
$pieces[0] = $in -> read_snafooz_piece_from_file(
    PIECE1 );
$pieces[0] -> serial(0);
print "done\n";

print "creating piece 2 from '".PIECE2."'...";
$pieces[1] = $in -> read_snafooz_piece_from_file(
    PIECE2 );
$pieces[1] -> serial(1);
print "done\n";


print <<EOF;

I will now test how many ways these two pieces can
connect with each other.

The expected result is:

Piece Side connects to Piece Side
---------------------------------
  0    0                 1     0
  0    1                 1     3

where the sides are numbered starting with 0 at the
top moving clockwise:

    ---------
    |   0   |
    | 3   1 |
    |   2   |
    --------

EOF

$s -> build_fit_db( \@pieces );

my @db;
$db[0] = $pieces[0] -> {objects} -> {fit};
$db[1] = $pieces[0] -> {objects} -> {reverse_fit};

foreach my $d ( @db ) {
    foreach my $k ( keys %{ $d } ) {
        my ( $p ) = $k =~ /^(.)/;
        my ( $ps ) = $k =~ /(.)$/;
        foreach ( @{ $d -> {$k} } ) {
            my ( $p2 ) = $_ =~ /^(.)/;
            my ( $p2s ) = $_ =~ /(.)$/;
            print "Piece $p Side $ps connects to",
                " Piece $p2 Side $p2s\n";
        }
    }
}

print "\nThe pieces look like this:\n";

foreach ( 0 .. @pieces-1 ) {
    print "  Piece $_\n";
    print "-----------\n";
    print $pieces[$_] -> to_string();
    print "-----------\n";
}

exit;
