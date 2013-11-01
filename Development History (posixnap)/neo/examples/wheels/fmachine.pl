#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Neopia::LostDesert::FruitMachine;
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
my $machine =
    Neopets::Neopia::LostDesert::FruitMachine -> new(
        { agent => \$agent,
          debug => $DEBUG,
	} );

print $machine -> spin(), "\n";

exit 0;
