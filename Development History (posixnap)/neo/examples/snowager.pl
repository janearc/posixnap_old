#!/usr/bin/perl -w

use strict;
use warnings;

use Neopets::Neopia::TerrorMountain::IceCaves::Snowager;
use Getopt::Long qw/:config bundling/;

my ( $DEBUG, $COOKIES );

GetOptions(
  'd'   => \$DEBUG,
  'c=s' => \$COOKIES,
);

my $snowager =
    Neopets::Neopia::TerrorMountain::IceCaves::Snowager -> new(
      { debug => $DEBUG,
      } );

print $snowager -> steal();

print "\n";

exit 0;
