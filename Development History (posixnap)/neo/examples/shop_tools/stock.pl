#!/usr/bin/perl -w

# Stock the store with items listed in NP_HOME/stock.txt
# only stocks one of each item

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Config;
use Neopets::Shops::Mine;
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
my $shop = Neopets::Shops::Mine -> new(
  { agent => \$agent,
    debug => $DEBUG
  } );

my $stock_file = $config -> read_config( { file => 'stock.txt' } );
my @items = keys %{ $stock_file };

my $response = $shop -> quickstock( \@items);

if ( $response )
  { print "$response\n" }

exit 0;
