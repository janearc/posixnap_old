#!/usr/bin/perl

use strict;
use warnings;
use Neopets::Pet;
use Data::Dumper;

my $pet = Neopets::Pet -> new();

my $current = $pet -> current_pet('thefirstfluffy');

print Dumper $current;
