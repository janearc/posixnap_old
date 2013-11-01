#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Config;
use Neopets::Shops::Mine;
use Neopets::Item::Simple;
use Getopt::Long qw/:config bundling/;
use Data::Dumper;

my ( $DEBUG, $COOKIES, $GREED );

GetOptions(
  'd'   => \$DEBUG,
  'c=s' => \$COOKIES,
  'g'   => \$GREED,
);

my $agent = Neopets::Agent -> new(
  { debug => $DEBUG,
    cookiefile => $COOKIES,
  } );
my $config = Neopets::Config -> new(
  { debug => $DEBUG } );
my $shop = Neopets::Shops::Mine -> new(
  { agent => \$agent,
    debug => $DEBUG,
  } );

# read the config file
my $price_file = $config -> read_config( { XML => 'prices.xml' } );

# make items out of the config
my @item_list;
if ( $price_file -> {xml} ) {
  foreach my $item ( keys %{ $price_file -> {item} } ) {
    my $new_item = Neopets::Item::Simple -> new(
      { name => $item,
        price => $price_file -> {item} -> {$item} -> {price} + defined $GREED ? $GREED : 0,
      } );
    push @item_list, $new_item;
  }
} else {
  foreach my $item ( keys %{ $price_file } ) {
    my $new_item = Neopets::Item::Simple -> new(
      { name => $item,
        price => $price_file -> {$item} -> {1} + ($GREED || 0),
      } );
    push @item_list, $new_item;
  }
}

# set the prices
$shop -> set_prices( @item_list );

exit 0;
