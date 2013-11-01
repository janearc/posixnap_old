#!/usr/bin/perl -w

BEGIN { $|++; print "1..126\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $c1, $c2, @coins, $m, $ch );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::City } );
test( eval { require PuzzleSolver::Diffusion::Coin } );
test( eval { require PuzzleSolver::Diffusion::Motif } );
test( $m = PuzzleSolver::Diffusion::Motif -> new( name => "foo" ) );
foreach( 1 .. 100 ) {
    test( push @coins, PuzzleSolver::Diffusion::Coin -> new( motif => $m ) ) }
test( $c1 = PuzzleSolver::Diffusion::City -> new( coins => \@coins ) );
test( $c2 = PuzzleSolver::Diffusion::City -> new( coins => [ $coins[0] ] ) );
test( (! $c1 -> is_equal( $c2 ) ) );
test( $c1 -> is_equal( $c1 ) );
test( @{ $c1 -> coins() } == 100 );
test( @{ $c2 -> coins() } == 1 );
test( $c2 -> set_coins( \@coins ) );
test( @{ $c2 -> coins() } == 100 );
test( (! $c1 -> country() ) );
test( $ch = {} );
test( $ch -> {$m -> name} = 100 );
test( $c1 -> set_hash_coins( $ch ) );
test( ref $c1 -> coins() eq 'HASH' );
test( $ch = $c1 -> coins() );
test( $ch -> {$m -> name} == 100 );

test( eval{ PuzzleSolver::Diffusion::City::_test_city( $c1 ) } );
test( (! eval{ PuzzleSolver::Diffusion::City::_test_city( 2 ) } ) );
test( (! eval{ PuzzleSolver::Diffusion::City::_test_city( [ ] ) } ) );
test( eval { PuzzleSolver::Diffusion::City::_test_cities( [ $c1, $c2 ] ) } );
test( eval { PuzzleSolver::Diffusion::City::_test_cities( [ ] ) } );
test( (! eval { PuzzleSolver::Diffusion::City::_test_cities( \@coins ) } ) );


exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
