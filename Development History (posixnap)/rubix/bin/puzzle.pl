#!/usr/bin/perl -w

use strict;
use warnings;

use Rubix::IO;
use Rubix::Cube;
use Rubix::Solver;

my $s = Rubix::Solver -> new();
my $io = Rubix::IO -> new();
my $c = Rubix::Cube -> new();

$c = $io -> get_cube();

my $solved_cube = $s -> solve( $c );

if ( $solved_cube -> done() ) {
    $io -> display_solution();
} else {
    print "This cube is not solvable without magic markers\n";
}
