#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Neopia::Faerieland::WheelOfExcitement;
use Getopt::Long qw/:config bundling/;

my ( $DEBUG, $COOKIES );

GetOptions(
  'd'   => \$DEBUG,
 'c=s' => \$COOKIES,
);

my $agent = Neopets::Agent -> new(
  { debug => $DEBUG,
    cookiefile => $COOKIES,
  } );
my $wheel =
    Neopets::Neopia::Faerieland::WheelOfExcitement -> new(
        { agent => \$agent,
	  debug => $DEBUG,
	} );

print $wheel -> spin(), "\n";

exit 0;
