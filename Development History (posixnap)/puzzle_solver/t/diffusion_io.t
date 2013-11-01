#!/usr/bin/perl -w

BEGIN { $|++; print "1..3\n"; }
END   { print "not ok 1" unless $looks_good }

use strict;
use warnings;
use vars qw/$looks_good/;
$looks_good = 1;

my ( $i, $io );

test( 1 );
test( eval { require PuzzleSolver::Diffusion::IO } );
test( $io = PuzzleSolver::Diffusion::IO -> new() );

exit;

sub test {
    $i++;
    print $_[0] ? "" : "not ",
        "ok $i",
        $_[1] ? " $_[1]" : "", "\n";
}
