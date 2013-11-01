#!/usr/bin/perl

use warnings;
use strict;

use Neopets::Agent;
use Neopets::Shops;
use Neopets::Neopia::MysteryIsland::TrainingSchool;

use Getopt::Long qw/:config bundling/;
use Data::Dumper;

my ( $DEBUG, $COOKIES );

GetOptions(
  'd'   => \$DEBUG,
  'c=s' => \$COOKIES,
);


my ($petname, $discipline) = (@ARGV);
die "$0: mcfly: please provide a petname" unless $petname;

my $agent	= Neopets::Agent -> new( { debug => $DEBUG, cookiefile => $COOKIES } );
my $school	= Neopets::Neopia::MysteryIsland::TrainingSchool -> new(
                  { agent => \$agent, debug => $DEBUG } );
my $shop	= Neopets::Shops -> new( { agent => \$agent, debug => $DEBUG } );

my ($pet) = grep { uc $_ -> {name} eq uc $petname } @{ $school -> pets() };
die "pet '$petname' not found\n" unless $pet;

$discipline = ucfirst $discipline;

if ($pet -> is_training()) {
	print $pet -> {name}." is currently training (".
		$pet -> it_to_localtime( $pet -> is_training(), "." )." remains).\n";
	exit 0;
}

if ($pet -> is_completed()) {
	$pet -> complete_course();
	sleep 3;
}
if ( my $cs = $pet -> cs_required()) {
	foreach my $stone ( @{ $cs } ) {
		$shop -> buy_direct( $stone )
			|| warn "Could not buy '$stone'\n";
	}
	$school -> pay_for_training( \$pet )
		and print $pet -> {name}." has been paid for\n";
}
die "$0: mcfly: please provide a discipline\n" unless $discipline;
$school -> train( \$pet, { Discipline => $discipline } );
sleep 3;
