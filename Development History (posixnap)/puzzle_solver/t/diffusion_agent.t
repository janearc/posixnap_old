#!/usr/bin/perl -w

BEGIN { $|++; print "1..257\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $c, $w, $a );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::Agent } );
test( eval { require PuzzleSolver::Diffusion::World } );
test( eval { require PuzzleSolver::Diffusion::Country } );
test( $a = PuzzleSolver::Diffusion::Agent -> new() );
test( $w = PuzzleSolver::Diffusion::World -> new( name => "earth" ) );
test( $w -> add_country(x1=>0,x2=>3,y1=>0,y2=>3,country_name=>"Germany",motif_name=>"Euro",coin_count=>10000000 ) );
test( $w -> add_country(x1=>4,x2=>5,y1=>0,y2=>3,country_name=>"Austria",motif_name=>"Mark",coin_count=>5000000 ) );

test( not eval { $a -> diffuse() } );
test( $a -> world( $w ) );
test( $w ->is_equal(  $a -> world() ) );
test( $a -> world() -> city( 3, 3 ) -> coins() -> {'Euro'} == 10000000 );

test( not $a -> world() -> complete(
        city => $a -> world() -> city( 3, 3 ) ) );
test( not $a -> world() -> complete(
        city => $a -> world() -> city( 0, 0 ) ) );

test( $a -> diffuse() );
test( not $w -> is_equal( $a -> world() ) );
test( $a -> world() -> city( 3, 3 ) -> coins() -> {'Euro'} == 9990000 );
test( $a -> world() -> city( 3, 3 ) -> coins() -> {'Mark'} == 5000 );
test( $a -> world() -> complete(
        city => $a -> world() -> city( 3, 3 ) ) );
test( not $a -> world() -> complete(
        city => $a -> world() -> city( 0, 0 ) ) );

test( $a -> diffuse() );
test( $a -> world() -> city( 3, 3 ) -> coins() -> {'Euro'} == 9980030 );
test( $a -> world() -> city( 3, 3 ) -> coins() -> {'Mark'} == 9985 );

# also test different constructor args
test( not eval { $a -> world( 1 ) } );
test( not eval { $a -> world( [ ] ) } );

test( not $a -> world() -> complete( country => "Germany" ) );

foreach ( 1 .. 114 ) {
    test( not $a -> world() -> complete( city => $a -> world() -> city( 0, 0 ) ) );
    test( $a -> diffuse() );
}

test( $a -> world() -> complete( city => $a -> world() -> city( 0, 0 ) ) );
test( $a -> world() -> complete( country => "Germany" ) );

test( not eval { $a -> world() -> complete() } );

exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
