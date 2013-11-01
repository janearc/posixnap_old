#!/usr/bin/perl -w

BEGIN { $|++; print "1..8\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $m1, $m2 );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::Motif } );
test( $m1 = PuzzleSolver::Diffusion::Motif -> new( name => "foo" ) );
test( $m2 = PuzzleSolver::Diffusion::Motif -> new() );
test( $m1 -> name() eq "foo" );
test( (! $m2 -> name() ) );
test( (! $m1 -> is_equal( $m2 ) ) ); 
test( $m1 -> is_equal( $m1 ) );


exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
