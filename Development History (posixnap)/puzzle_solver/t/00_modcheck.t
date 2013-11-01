#!/usr/bin/perl -w

BEGIN { $|++; print "1..18\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $m1, $m2 );

test( 1 );
test( eval { require Clone }, "# testing for mod Clone" );
test( eval { require File::Slurp }, "# testing for mod File::Slurp" );
test( eval { require PuzzleSolver::Diffusion::Agent } );
test( eval { require PuzzleSolver::Diffusion::City } );
test( eval { require PuzzleSolver::Diffusion::Coin } );
test( eval { require PuzzleSolver::Diffusion::Country } );
test( eval { require PuzzleSolver::Diffusion::Motif } );
test( eval { require PuzzleSolver::Diffusion::World } );
test( eval { require PuzzleSolver::Geometry::Line } );
test( eval { require PuzzleSolver::Geometry::Point } );
test( eval { require PuzzleSolver::Geometry::Shape } );
test( eval { require PuzzleSolver::Graph::Container } );
test( eval { require PuzzleSolver::Graph::Node } );
test( eval { require PuzzleSolver::IO::Read } );
test( eval { require PuzzleSolver::Snafooz::Piece } );
test( eval { require PuzzleSolver::Snafooz::Side } );
test( eval { require PuzzleSolver::Snafooz::Solver } );



exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
