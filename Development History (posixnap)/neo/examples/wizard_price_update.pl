#!/usr/bin/perl -w

  # constants
  # atm, these files must be xml or
  # #2 : delimited lists
  # there is no support for writing
  # old : delimited files
use constant BUY_FILE => 'wizard.xml';
use constant SELL_FILE => 'prices.xml';
use constant GREED => 150;
use constant LARGESS => 50;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Config;
use Neopets::Shops::Wizard;
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
my $config = Neopets::Config -> new(
  { debug => $DEBUG } );
my $wizard = Neopets::Shops::Wizard -> new(
  { agent => \$agent,
    debug => $DEBUG } );

  # get files
my $buy_file = $config -> read_config( { XML => BUY_FILE } );
my $sell_file = $config -> read_config( { XML => SELL_FILE } );

  # foreach item
foreach my $item ( keys %{ $buy_file -> {item} } ) {
  print "$item ...\n";

  my $stat = $wizard -> statistics( $item );
  my @data = $stat -> get_data();

  my $old_buy_price = $buy_file -> {item} -> {$item} -> {price};
  my $old_sell_price = $sell_file -> {item} -> {$item} -> {price};

  my $new_buy_price = $data[3] - GREED;
  my $new_sell_price = $data[3] - LARGESS;

    # debugging
  if ( $DEBUG ) {
    print "buy:\n";
    print "\told: $old_buy_price new: $new_buy_price\n";
    print "sell:\n";
    print "\told: $old_sell_price new: $new_sell_price\n";
  }

  $buy_file -> {item} -> {$item} -> {price} = $new_buy_price;
  $sell_file -> {item} -> {$item} -> {price} = $new_sell_price;
}

  # set timestamps
$buy_file -> {date} = time();
$sell_file -> {date} = time();

$config -> write_config( { XML => BUY_FILE, contents => $buy_file, root => 'wizard-search-list' } );
$config -> write_config( { XML => SELL_FILE, contents => $sell_file, root => 'store-price-list' } );

exit 0;
