#!/usr/bin/perl -wl

use strict;
use warnings;
use Neopets::Agent;
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
my $shop = Neopets::Shops::Mine -> new( { agent => \$agent } );

my $history = $shop -> history();

foreach my $sale (@{ $history }) {
	print join "\t", (
		$sale -> date(),
		$sale -> buyer(),
		$sale -> price(),
		$sale -> name(),
	);
}

exit 0;
