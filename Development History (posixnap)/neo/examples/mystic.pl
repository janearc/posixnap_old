#!/usr/bin/perl -w

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Neopia::MysteryIsland::IslandMystic;
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
my $mystic =
  Neopets::Neopia::MysteryIsland::IslandMystic -> new(
    { agent => \$agent,
      debug => $DEBUG, } );

print $mystic -> consult(), "\n";

exit 0;
