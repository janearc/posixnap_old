#!/usr/bin/perl -w

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Pet;
use Neopets::Neopia::Central::MarketPlace::SoupKitchen;

my $agent = Neopets::Agent -> new();
my $pet = Neopets::Pet -> new({agent=>\$agent});
my $sk = Neopets::Neopia::Central::MarketPlace::SoupKitchen -> new({agent=>\$agent});

my @pets = @{ $pet -> lookup_user_pets( $agent -> username() ) };

use Data::Dumper;
print Dumper \@pets;

foreach my $p ( @pets ) {
  $sk -> feed( $p ) ? print "success\n" : print "ouch\n";
}
