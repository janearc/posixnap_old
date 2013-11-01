#!/usr/bin/perl -w

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Neopia::MysteryIsland::Tombola;
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
my $tombala = Neopets::Neopia::MysteryIsland::Tombola -> new({ agent => \$agent });

print $tombala -> grab(), "\n";

exit 0;
