#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Neopia::LostDesert::ColtzansShrine;
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
my $shrine =
  Neopets::Neopia::LostDesert::ColtzansShrine -> new(
    { agent => \$agent,
      debug => $DEBUG } );

print $shrine -> visit(), "\n";

exit 0;
