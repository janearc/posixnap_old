#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Neopets::Agent;
use Neopets::Neopia::Central::Bank;

my $agent = Neopets::Agent -> new({});
my $bank = Neopets::Neopia::Central::Bank -> new( { agent => \$agent, });

my $rates = $bank -> info();
$bank -> collect_interest();
$bank -> deposit( 1 );
$bank -> withdraw( 1 );
print Dumper $rates;
