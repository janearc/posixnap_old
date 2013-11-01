#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Neopia::Faerieland::HealingSprings;
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
my $spring =
    Neopets::Neopia::Faerieland::HealingSprings -> new(
        { agent => \$agent,
	  debug => $DEBUG,
	} );

print $spring -> heal(), "\n";

exit 0;
