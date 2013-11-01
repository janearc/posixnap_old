#!/usr/bin/perl -w

# take an item name for input,
# search for it, and buy it
#
# item name must be complete and
# in good case

$|++;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Shops;
use Neopets::Item::Simple;
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
    debug => $DEBUG, } );

my ( $name ) = $agent -> username();

# get item name
print "item : ";
my $item_name = <>;
chomp $item_name;

if ( $shop -> buy_direct( $item_name ) )
  { print "Got it!\n" }
else
  { print "Didn't get it..\n" }

exit 0;
