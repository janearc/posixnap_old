#!/usr/bin/perl

use strict;
use warnings;
use Neopets::Shops;
use Neopets::Neopia::Meridell::IllusensGlade;


my $illusen =
    Neopets::Neopia::Meridell::IllusensGlade -> new();
my $shop =
    Neopets::Shops -> new();

my $item = $illusen -> begin();
die unless $item;
$shop -> buy_direct( $item );

if ( my $response = $illusen -> finish() ) {
    print "$response\n";
}
