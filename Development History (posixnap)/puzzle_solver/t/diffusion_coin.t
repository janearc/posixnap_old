#!/usr/bin/perl -w

BEGIN { $|++; print "1..18\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $m, $c1, $c2 );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::Coin } );
test( eval { require PuzzleSolver::Diffusion::Motif } );
test( $c1 = PuzzleSolver::Diffusion::Coin -> new(
    motif => PuzzleSolver::Diffusion::Motif -> new( name => "foo" ) ) );
test( $c2 = PuzzleSolver::Diffusion::Coin -> new() );
test( $c1 -> motif() -> name() eq "foo" );
test( (! $c2 -> motif() -> name() ) );
test( (! $c1 -> is_equal( $c2 ) ) ); 
test( $c1 -> is_equal( $c1 ) );
test( $m = PuzzleSolver::Diffusion::Motif -> new( name => "test" ) );
test( $c1 -> motif( $m ) );
test( $c1 -> motif() -> is_equal( $m ) );
test( eval { PuzzleSolver::Diffusion::Coin::_test_coin( $c1 ) } );
test( (! eval { PuzzleSolver::Diffusion::Coin::_test_coin( 2 ) } ) );
test( (! eval { PuzzleSolver::Diffusion::Coin::_test_coin( [ ] ) } ) );
test( eval { PuzzleSolver::Diffusion::Coin::_test_coins( [ $c1, $c2 ] ) } );
test( eval { PuzzleSolver::Diffusion::Coin::_test_coins( [ ] ) } );
test( (! eval { PuzzleSolver::Diffusion::Coin::_test_coins( [ 1, 2 ] ) } ) );


exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
