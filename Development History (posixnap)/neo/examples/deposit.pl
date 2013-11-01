#!/usr/bin/perl -w

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Neopia::Central::Bank;
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
my $bank =
  Neopets::Neopia::Central::Bank -> new(
    { agent => \$agent,
      debug => $DEBUG } );

$bank -> deposit( 20 );
$bank -> withdraw( 20 );
$bank -> collect_interest();
