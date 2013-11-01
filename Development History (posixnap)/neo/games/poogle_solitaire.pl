#!/usr/bin/perl -w

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Games::PoogleSolitaire;

my $agent = Neopets::Agent -> new();
my $poogle = Neopets::Games::PoogleSolitaire -> new( \$agent );

#my $state = $poogle -> scan;
$poogle->begin;
$poogle->solve_canned;
