#!/usr/bin/perl -w

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Neopia::Tyrannia::Plateau::Omelette;
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
my $omelette =
  Neopets::Neopia::Tyrannia::Plateau::Omelette -> new(
    { agent => \$agent } );

print $omelette -> get()."\n";

exit 0;
