#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Games::Cliffhanger;

use constant EASY => 1;
use constant MEDIUM => 2;
use constant HARD => 3;

my $agent = Neopets::Agent -> new();
my $cliffhanger = Neopets::Games::Cliffhanger -> new( \$agent );

$cliffhanger -> load_words();
my $response = $cliffhanger -> begin( HARD );
my $answer = $cliffhanger -> find_solution( );
$cliffhanger -> solve( $answer || 'The answer was not found' );

print "answer : $answer\n";
