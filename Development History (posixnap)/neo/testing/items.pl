#!/usr/bin/perl

use warnings;
use strict;

use Neopets::Agent;
use Neopets::Shops::Item;
use Neopets::Shops::Mine;
use Data::Dumper;
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
my $my_shop = Neopets::Shops::Mine -> new( \$agent );

my $inventory = $my_shop -> inventory();

foreach my $item (@{ $inventory }) {
	my $info = $item -> info();
	next unless $item -> info() -> {name} =~ /now/;
	$item -> to_friend( 'risacher' )
		and warn "gave ".$info -> {name}." to risacher\n";
}
