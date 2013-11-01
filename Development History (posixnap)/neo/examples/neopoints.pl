#!/usr/bin/perl -l

use warnings;
use strict;

use Neopets::Agent;

my $agent = Neopets::Agent -> new({ });

print $agent -> username()." has ".$agent -> neopoints()." NP. groovy.";
exit 0;
