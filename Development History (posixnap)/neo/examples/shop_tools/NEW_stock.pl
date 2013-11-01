#!/usr/bin/perl -w

# Stock the store with items listed in NP_HOME/stock.txt
# only stocks one of each item
# alpha release :)

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Shops::Item;
use Neopets::Shops::Mine;
use File::Slurp;

my $DEBUG = 1;

my $agent = Neopets::Agent -> new();
my $my_shop = Neopets::Shops::Mine -> new( \$agent );

my @intentory = @{ $my_shop -> inventory() };

my @stock_items = read_file( $ENV{NP_HOME}.'/stock.txt' );

foreach my $stock_item ( @stock_items ) {
  chomp $stock_item;
  print "Attempting to stock '$stock_item'\n";
  
  foreach my $item ( @intentory ) {
    my $item_info = $item -> info();
    if ($item_info -> {name} eq $stock_item) {
        $item -> to_shop( $item_info );
	$DEBUG && print "sent item ".$item -> {ID}." to the shop.\n";
    }
  }
}

exit 0;
