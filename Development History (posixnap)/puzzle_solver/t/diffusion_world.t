#!/usr/bin/perl -w

BEGIN { $|++; print "1..32\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $motif, $w1, $w2, $c1, $s, $ci );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::World } );
test( eval { require PuzzleSolver::Diffusion::Country } );
test( eval { require PuzzleSolver::Diffusion::Motif } );
test( eval { require PuzzleSolver::Diffusion::Coin } );
test( $motif = PuzzleSolver::Diffusion::Motif -> new( name => "wrench" ) );
test( $c1 = PuzzleSolver::Diffusion::Country -> new( name => "garage" ) );
test( $w1 = PuzzleSolver::Diffusion::World -> new( name => "neighborhood" ) );
test( $w2 = PuzzleSolver::Diffusion::World -> new( ) );
test( (! $w1 -> is_equal( $w2 ) ) );
test( $w1 -> is_equal( $w1 ) );

test( $w1 -> add_country( country => $c1, motif => $motif,
    x1 => 2, x2 => 4, y1 => 1, y2 => 5, coin_count => 2 ) );
test( (! eval { $w1 -> add_country( country_name => "tv dinner", motif => $motif,
    x1 => 2, x2 => 4, y1 => 1, y2 => 5, coin_count => 2 ) } ) );
test( $w1 -> add_country( country_name => "tv dinner", motif => $motif,
    x1 => 5, x2 => 7, y1 => 1, y2 => 2, coin_count => 2 ) );
test( $w1 -> add_country( country_name => "sofa cushion", motif_name => "dust bunnies",
    x1 => 8, x2 => 9, y1 => 1, y2 => 2, coin_count => 2 ) );

test( $w2 -> add_country( country => $c1, motif => $motif,
    x1 => 2, x2 => 3, y1 => 1, y2 => 2 ) );

test( $ci = $w1 -> city( 3, 3 ) );
test( @{ $ci -> connections() } == 4 );

test( $ci -> country() -> is_equal( $c1 ) );
test( %{ $ci -> coins() } -> {'wrench'} == 2 );
test( $w1 -> city( 8, 1 ) -> country() -> name() eq "sofa cushion" );
test( $s = $w1 -> space() );
test( (! $s -> {0} -> {0} ) );

test( %{ $w2 -> city( 3, 2 ) -> coins() } -> {$motif -> name()} == 1000000 );

test( (! eval { $w1 -> add_country( motif => $motif,
    x1 => 2, x2 => 4, y1 => 1, y2 => 5 ) } ) );
test( (! eval { $w1 -> add_country( country => $c1,
    x1 => 2, x2 => 4, y1 => 1, y2 => 5 ) } ) );
test( (! eval { $w1 -> add_country( country => $c1, motif => $motif,
    x1 => 2, x2 => 4, y1 => 1 ) } ) );

test( @{ $w1 -> motifs() } == 2 );
test( @{ $w2 -> motifs() } == 1 );

test( eval { PuzzleSolver::Diffusion::World::_test_world( $w1 ) } );
test( (! eval { PuzzleSolver::Diffusion::World::_test_world( 2 ) } ) );
test( (! eval { PuzzleSolver::Diffusion::World::_test_world( [ ] ) } ) );

exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
