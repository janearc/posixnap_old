#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Neopets::Agent;
use Neopets::Games::NeoQuest;

my ( $DEBUG, $AUTO );

GetOptions(
  'd' => \$DEBUG,
  'a' => \$AUTO,
);

my $agent = Neopets::Agent -> new ();
my $quest = Neopets::Games::NeoQuest -> new ( \$agent );

  # set vars according to flags
$DEBUG and $quest -> nq_switch_debug( $DEBUG );
$AUTO and $quest -> nq_switch_battle_interactive( 0 );

$quest -> nq_main();

exit 0;
