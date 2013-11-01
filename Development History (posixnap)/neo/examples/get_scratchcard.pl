#!/usr/bin/perl

use warnings;
use strict;

use Neopets::Neopia::TerrorMountain::IceCaves::Kiosk;
use Neopets::Agent;
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
my $wocky =
  Neopets::Neopia::TerrorMountain::IceCaves::Kiosk -> new(
    { agent => \$agent,
      debug => $DEBUG, } );

$wocky -> get_card() 
	or die "did not get card\n";
