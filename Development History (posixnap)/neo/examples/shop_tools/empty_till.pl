#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
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
my $shop = Neopets::Shops::Mine -> new( 
  { agent => \$agent,
    debug => $DEBUG,
  } );


if ( my $np = $shop -> get_till() ) {
  print "Withdrawing $np\n";
  $shop -> empty_till();
} else {
  print "The till is empty\n";
}
