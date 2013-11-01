#!/usr/bin/perl

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Shops;
use Neopets::Neopia::Central::MoneyTree;
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
my $shop = Neopets::Shops -> new(
  { agent => \$agent,
    debug => $DEBUG } );
my $tree =
  Neopets::Neopia::Central::MoneyTree -> new(
    { agent => \$agent,
      debug => $DEBUG } );

my @itemlist = @{ $tree -> get_list() };

my $tries = 0;
foreach my $item ( @itemlist ) {
  if ( ( $item -> name() =~ / NP/ )
   and ( $shop -> buy( $item ) ) ) {
    warn "yay, got money.\n";
    exit 0;
  } else {
    warn "no stuff. :(\n";
    $tries++;
    exit 0 if $tries > 3;
  }
}
