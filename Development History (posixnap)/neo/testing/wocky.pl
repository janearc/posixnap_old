#!/usr/bin/perl

use warnings;
use strict;

use Neopets::Agent;
use Neopets::Neopia::TerrorMountain::IceCaves::Kiosk;
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
my $kiosk =
  Neopets::Neopia::TerrorMountain::IceCaves::Kiosk -> new(
    { agent => \$agent,
      debug => $DEBUG, } );

$kiosk -> scratch();

die;
