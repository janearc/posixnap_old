#!/usr/bin/perl -w

BEGIN { $|++; print "1..28\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $c1, $c2, @cities );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::Country } );
test( eval { require PuzzleSolver::Diffusion::City } );
foreach ( 1 .. 10 ) {
    test( push @cities, PuzzleSolver::Diffusion::City -> new() );
}
test( $c1 = PuzzleSolver::Diffusion::Country -> new( name => "foo", cities => \@cities ) );
test( $c2 = PuzzleSolver::Diffusion::Country -> new() );
test( $c1 -> name() eq "foo" );
test( (! $c2 -> name() ) );
test( (! $c1 -> is_equal( $c2 ) ) ); 
test( $c1 -> is_equal( $c1 ) );
test( @{ $c1 -> cities() } == 10 );
test( $c2 -> cities( $c1 -> cities() ) );
test( @{ $c2 -> cities() } == 10 );
test( eval { PuzzleSolver::Diffusion::Country::_test_country( $c1 ) } );
test( (! eval { PuzzleSolver::Diffusion::Country::_test_country( 2 ) } ) );
test( (! eval { PuzzleSolver::Diffusion::Country::_test_country( [ ] ) } ) );
test( eval { PuzzleSolver::Diffusion::Country::_test_countries( [ $c1, $c2 ] ) } );
test( eval { PuzzleSolver::Diffusion::Country::_test_countries( [ ] ) } );
test( (! eval { PuzzleSolver::Diffusion::Country::_test_countries( [ 1, 2 ] ) } ) );

exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
