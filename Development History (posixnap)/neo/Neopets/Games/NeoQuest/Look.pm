package Neopets::Games::NeoQuest::Look;

use constant NQ_URL => 'http://www.neopets.com/games/neoquest/neoquest.phtml';

use strict;
use warnings;
use Term::ANSIColor qw/:constants/;
use Exporter;
use Data::Dumper;

use vars qw/@ISA @EXPORT $VERSION/;

@EXPORT = qw/nq_look nq_look_passage_get nq_look_talk_get/;
@ISA = qw/Exporter/;
$VERSION = 0.01;

#   
# -- Look section --
#
      
# display the map
# takes $response (HTTP::Response, optional)
# returns HTTP::Response
sub nq_look {
  my $self = shift;

  my $response = shift || $self -> get_url();
      
    # enter battle if necessary
  if ( $self -> nq_is_battle( $response ) )
    { $response = $self -> nq_battle_enter( $response ) }
      
  my @locs = grep { /WIDTH="40"/ } split '\n', $response;
  @locs = grep {! /="10"/ } grep { /^IMG.*="40"/ } split '><', $locs[0];

  my $d = int(sqrt(@locs));
  my $xmax = $d;
  my $ymax = $d;
      
  if ( ( $response =~ "You are in the Mountain Fortress." )
    or ( $response =~ "You are in the Palace of the Two Rings." ) ) {
    $xmax = 7;
    $ymax = 9; 
  } elsif ( $response =~ "You are in Kal Panning." ) {
    $xmax = 7;
    $ymax = 8;
  }

    # pints the dimensions
  if ( $self -> {objects} -> {NQ} -> {DEBUG} ) {
    print "($xmax,$ymax) ( from $d )\n"; }

    # notify if unspent skill points
  if ( $response =~ "Spend Skill Points" )
    { print RED, "Skill points\n", RESET }

  print "-"x(1+$xmax*3);
  for(my $y=0; $y<$ymax; $y++) {
    print "\n|";
      # each col of each row
    for(my $x=0; $x<$xmax; $x++) {
        # print terrain
      nq_look_terrain_print ( $locs[$y*$xmax+$x] );
      print "|";
    }
  }
  print "\n";
  print "-"x(1+$xmax*3);
  print "\n";

  my $passage = $self -> nq_look_passage_get ($response);
  if ($passage) {
    print "You see a passage ($passage)\n";
  }
  
  my %conv = %{ $self -> nq_look_talk_get($response) };
  if ( %conv ) {
    print "You see $_ here.\n" for keys %conv;
  }

  return $response;
}

# get a passage link
# takes $response (HTTP::Response, optional)
# if passage link exists, return link in
#  'movelink=\d' format
# else, returns nothing
sub nq_look_passage_get {
  my $self = shift;

  my $response = shift || $self -> get_url();
  my @opts = grep { /WIDTH="40"/ } split '\n', $response;
  @opts = grep { /Go!/ } split '<A', $opts[0];
  if (@opts) {
    my $link;
    ($link = $opts[0]) =~ s/.*(movelink=\d+).*/$1/;
    return $link;
  } else {
    return;
  }
}

# get a conversation link for npcs
# takes $response (HTTP::Response, optional)
# if conversation exists, return link(s) in
#  array ref
# else, returns nothing
sub nq_look_talk_get {
  my $self = shift;

  my $response = shift || $self -> get_url();

  if ( $response =~ "You see" ) {
    my @conv_arr = $response =~ m/You see ([^<]+) here.<BR><A HREF="([^"]+)/g;
    my %conv = ( );
    while ( @conv_arr )
      { map { $conv{ $_->[0] } = $_->[1] } [ shift @conv_arr, shift @conv_arr ] }
    return \%conv;
  }
  return { };
}



# prints a 2 character terrain based on url
# takes $terrain (url)
# should only be used by nq_lool()
sub nq_look_terrain_print {
  my @data = split ' ', shift;
  my $terrain = $data[1];

  my %top_terrains = (
    unique    => [ BOLD, BLUE, ON_YELLOW, '??', RESET ],
    npc       => [ BOLD, BLUE, ON_YELLOW, '8 ', RESET ],
    chair     => [ BOLD, ON_WHITE, ' h', RESET ],
    table     => [ BOLD, ON_WHITE, 'nn', RESET ],
    up        => [ BOLD, 'UU', RESET ],
    down      => [ BOLD, 'DD', RESET ],
    barrel    => [ BOLD, RED, ON_WHITE, 'o=', RESET ],
    crate     => [ BOLD, RED, ON_WHITE, 'xx', RESET ],
    exit      => [ YELLOW, '||', RESET ],
    city      => [ BOLD, '[]', RESET ],
    castle    => [ BOLD, '$$', RESET ],
    door      => [ BOLD, ON_YELLOW, '{}', RESET ],
    carpet    => [ BLACK, ON_RED, '==', RESET ],
    ruins     => [ '##' ],
    pillar    => [ BLACK, ON_WHITE, '][', RESET ],
    portal    => [ BLUE, BOLD, '()', RESET ],
  );

  my %bot_terrains = (
    jungle    => [ BLACK, ON_GREEN, 'TT', RESET ],
    desert    => [ BLACK, ON_YELLOW, '==', RESET ],
    stone     => [ BLACK, ON_BLUE, '||', RESET ],
    water     => [ ON_BLUE, '~~', RESET ],
    hills     => [ '^^', RESET ],
    mountain  => [ '/\\', RESET ],
    swamp     => [ ON_GREEN, '##', RESET ],
    dirt      => [ BLACK, ON_BLUE, '||', RESET ],
    grassland => [ ON_GREEN, '  ', RESET ],
    cave      => [ BLACK, ON_YELLOW, '::', RESET ],
    dungeon   => [ ON_WHITE, '  ', RESET ],
    forest    => [ ON_GREEN, '}{', RESET ],
  );

  if ( $terrain =~ 'lupe' ) {
    print '00';
    return;
  }

    # this is redundant, put both hashes in an array/hash?
  foreach my $t ( keys %top_terrains ) {
    if ( $terrain =~ $t ) {
      print @{ $top_terrains{$t} };
      return;
    }
  }

  foreach my $t ( keys %bot_terrains ) {
    if ( $terrain =~ $t ) {
      print @{ $bot_terrains{$t} };
      return;
    }
  }
  print '  ';
}

#
# -- end Look section --
#

1;
