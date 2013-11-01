package Neopets::Games::NeoQuest::Battle;

use constant NQ_URL => 'http://www.neopets.com/games/neoquest/neoquest.phtml';

use strict;
use warnings;
use Term::ANSIColor qw/:constants/;
use Exporter;
use Data::Dumper;

use vars qw/@ISA @EXPORT $VERSION/;

@EXPORT = qw/nq_battle_enter nq_battle_status nq_battle_action_get nq_battle_is_avail nq_battle_cast nq_battle_item nq_battle_do_nothing nq_battle_help nq_battle_attack/;
@ISA = qw/Exporter/;
$VERSION = 0.01;

# 
# -- Battle section --
#   
  
# enter the battle
# if $NQ{INTERACTIVE} is set, will run a battle prompt
# else will act according to %actions
# can take $response (HTTP::Response)
sub nq_battle_enter {
  my $self = shift;
  my $response = shift || $self -> get_url();

  my $url = NQ_URL;
  my $interactive = $self -> {objects} -> {NQ} -> {INTERACTIVE};

  my $fight = $self -> nq_is_battle( $response );

  return unless ( $fight );

    # functions and params for automatic battle
    # attack and do nothing are not included
    #  as they are special cases
  my %actions = (
    'Cast Absorption' => {
        func  => \&nq_battle_cast,
        param => [ 'Absorb' ] },
    'Cast <I>Elemental Resistance</I>' => {
        func  => \&nq_battle_cast,
        param => [ 'Elemental Resistance' ] },
  );

  my $round = 1;

  while ($fight) {
      # catch end of fight
    if ( $response =~ 'You defeated' ) {
      $fight = 0;
      goto NEXT_ROUND;
    } elsif ( $response =~ 'You were defeated' ) {
      print " <> You sucked, have fun walking from town\n";
      return $self -> get_url( NQ_URL.'?end_fight=1' );
    } elsif (! ( $response =~ 'Attack' ) ) {
      $response = $self -> nq_battle_do_nothing();
      goto NEXT_ROUND;
    }

    if ($interactive) { # get prompt and act if interactive
      $self -> nq_battle_status( $round++, $response );
      ($response, $interactive) = $self -> nq_battle_action_get( $response );
    } else { # else, parse %actions and act
      foreach ( keys %actions ) {
          # if an action is possible, act, then goto next round
        if ( $self -> nq_battle_is_avail ( $_, $response ) ) {
         $response = $actions{$_} -> {func} -> ( $self, $actions{$_} -> {param} );
          goto NEXT_ROUND; }
    }

      # attack if no action found
      $response = $self -> nq_battle_attack();
      NEXT_ROUND:
    }
  }

    # end of battle parsing
  $response = $self -> get_url();
  print RED, " <> ", RESET, "You are victorious!\n";
    #
    # -- should check for items here, fix this --
    #
    # check for experience
  if ($response =~ "carrying") {
    print RED, " <> ", RESET, "Found Items\n";
    my @items = $response =~ m/carrying <B>([^<]+)/g;
    foreach my $item ( $response =~ m/carrying <B>([^<]+)/g ) {
      print "\t$item\n";
    }
  }
  if ($response =~ "experience points</B>") {
    my ( $exp ) = $response =~ m/\W(\d+)\Wexperience/;
    print RED, " <> ", RESET, "You gain $exp experience\n";
      # check for level
    if ($response =~ "YOU GAIN A NEW LEVEL") {
      print YELLOW, " <-> ", RESET, "YOU GAIN A LEVEL\n"; }
  }
  if ($response =~ "awarded a bonus") {
    my ( $bonus ) = $response =~ m/bonus of<BR><B>([^<]+)/;
    print YELLOW, " <-> ", RESET, "You got a bonus of $bonus\n";
  }

  return $self -> get_url ( NQ_URL."?end_fight=1" );
}

# battle shell
# takes $response (HTTP::Response)
# returns ( $response, $interactive )
sub nq_battle_action_get {
  my $self = shift;

  my $response = shift || $self -> get_url();

  $self -> {objects} -> {NQ} -> {DEBUG} && print "nq_battle_action_get( $response )\n";

  while (1) {
    print RED "fight> ", RESET;
    my $cmd = <>;
    chomp $cmd;

    my %dispatch = (
      'kill' => [ '?fact=attack', 0 ],
      'hit' => [ '?fact=attack', 1 ],
      'absorb' => [ '?fact=special&type=4003', 1 ],
      'wait' => [ '?fact=noop', 1 ],
      'heal weak' => [ '?fact=item&type=220000', 1 ],
      'fire' => [ '?fact=special&type=1003', 1 ],
    );

    if ( $dispatch{ $cmd } ) {
      $response = $self -> get_url( NQ_URL.${ $dispatch{$cmd} }[0] );
      my $interactive = ${ $dispatch{$cmd} }[1];
      return ( $response, $interactive );
    } else {
      $self -> nq_battle_help( \%dispatch );
    }
  }
}

# display status while in battle
# takes $round, $response (HTTP::Response, optional)
sub nq_battle_status {
  my $self = shift;

  my $round = shift;
  my $response = shift || get_();
  print "   -------------\n | Round: $round\n   -------------\n";
  $self -> nq_status_player( $response );
  print "   -------------\n";
  $self -> nq_status_opponent( $response );
  print "   -------------\n";

  return $response;
}

# return if a spell is available
# takes $spell, $response (HTTP::Response, optional)
sub nq_battle_is_avail {
  my $self = shift;

  my $spell = shift;
  my $response = shift || $self -> get_url();

  $self -> {objects} -> {NQ} -> {DEBUG} && print "nq_battle_is_avail( $spell, $response )\n";

  return $response =~ $spell;
}

# casts a spell in battle
# takes $spell
#  where $spell is a string,
#  or an array containing a string
# returns HTTP::Response
sub nq_battle_cast {
  my $self = shift;

  my $spell = shift;
  ref $spell and $spell = ${ $spell }[0];

  $self -> {objects} -> {NQ} -> {DEBUG} && print "nq_battle_cast( $spell )\n";

  my %spells = (
    'Cast Absorption' => '?fact=special&type=4003',
    Absorb => '?fact=special&type=4003',
  );

  if ( $spells{$spell} ) {
    print RED, " <> ", RESET, "Casting $spell\n";
    return $self -> get_url( NQ_URL.$spells{$spell} );
  } else {
    print "Unknown spell : \'$spell\'\n";
    return $self -> get_url();
  }
}

# uses an item in battle
# takes $item
#  where $item is a string,
#  or an array containing a string
# returns HTTP::Response
sub nq_battle_item {
  my $self = shift;

  my $item = shift;

  my %items = (
    'Weak Healing Potion' => '?fact=item&type=220000',
  );

  if ( $items{$item} ) {
    print " <> Using $item\n";
    return $self -> get_url( NQ_URL.$items{$item} );
  } else {
    print "Unknown item : \'$item\'";
    return $self -> get_url();
  }
}

# do nothing in a battle
# returns HTTP::Response
sub nq_battle_do_nothing {
  my $self = shift;
  return $self -> get_url( NQ_URL.'?fact=noop' );
}

# attack in battle
# returns HTTP::Response
sub nq_battle_attack {
  my $self = shift;
  print RED, " <> ", RESET, "Attacking\n";
  return $self -> get_url( NQ_URL.'?fact=attack' );
}

# displays help message in battle
# takes a reference to a hash and
#  displays its keys
sub nq_battle_help {
  my $self = shift;
  my %battle_disp = %{ shift() };
  foreach ( keys %battle_disp )
    { print "$_, " }
  print "\n";
}

#
# -- end Battle section --
#

1;
