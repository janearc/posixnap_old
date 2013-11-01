#!/usr/bin/perl

use warnings;
use strict;

use Neopets::Neopia::MysteryIsland::TrainingSchool;
use Neopets::Agent;
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
my $school	= Neopets::Neopia::MysteryIsland::TrainingSchool -> new( \$agent );

my $pets = $school -> pets();
foreach my $pet (@{ $pets }) {
	print $pet -> {name}. " is training\n" if $pet -> is_training();
}
my $pet = $pets -> [0];
#$school -> train( \$pet , { Discipline => 'Level' } );
if (my $cs = $pet -> cs_required()) {
	$school -> pay_for_training( \$pet )
		and print $pet -> {name}." has been paid for\n";
}

