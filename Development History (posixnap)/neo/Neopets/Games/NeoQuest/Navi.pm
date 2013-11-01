package Neopets::Games::NeoQuest::Navi;

use constant NQ_URL => 'http://www.neopets.com/games/neoquest/neoquest.phtml';

use strict;
use warnings;
use Term::ANSIColor qw/:constants/;
use File::Slurp;
use Neopets::Games::NeoQuest::Look;
use Exporter;

use vars qw/@ISA @EXPORT $VERSION/;

@EXPORT = qw/nq_navi_passage nq_navi nq_navi_mode_normal nq_navi_mode_sneak nq_navi_mode_hunt nq_navi_move nq_navi_mode/;
@ISA = qw/Exporter/;
$VERSION = 0.01;

#
# -- Navi section --
#

# navigate a passage, if one exists
# takes $response (HTTP::Response, optional)
# returns HTTP::Response
sub nq_navi_passage() {
  my $self = shift;

  my $response = shift || $self -> get_url();

    # enter battle if necessary
  if ($self -> nq_is_battle( $response )) {
    $response = $self -> nq_battle_enter( $response ) }

  my $passage = $self -> nq_look_passage_get( $response );
  if ($passage)
    { $self -> get_url( NQ_URL."?action=move&$passage" );
      $self -> nq_look() unless ( $self -> {objects} -> {NQ} -> {SCRIPT} ); }
  else
    { print "No passage found\n" }

  return $response;
}

# moves the character, 2se moves south east twice
# navi( $cmds ); this was called with the params.
# this made it impossible to send in multiple commands. is now fixed. aja
sub nq_navi {
  my $self = shift;

  my $cmd = shift; # this used to be an array. aja
  my $response = shift || $self -> get_url();

    # enter battle if necessary
  if ($self -> nq_is_battle( $response )) {
    $response = $self -> nq_battle_enter( $response );
  }

  $self -> {objects} -> {NQ} -> {DEBUG} and print "navi was passed: '$cmd'\n";

                # m 2se
                # m 2se 3s 4se

  $self -> {objects} -> {NQ} -> {DEBUG} and print "parsing moves...\n";

  my @moves = $cmd =~ m!
    (?:
      (\d+[a-z]{1,2})   | # 2se 2s 23se 23s
      ([a-z]{1,2})      | # se nw
      (\d+\s+[a-z]{1,2})  # 2 se
    )!xg;

  @moves =
  map  { s/^([a-z]{1,2})$/1$1/; $_ } # se -> 1se
    map  { y/ //d; $_ } # '1 se' -> 1se
      grep { defined and length } # lose the '' if its there
        @moves;

  if ($self -> {objects} -> {NQ} -> {DEBUG}) {
    foreach my $move (@moves)
      { print "'$move'\n" }
  }

  $response = $self -> nq_navi_move($_) for @moves;
  return $response;
}

# dispatch a nq move. navi is sufficiently complex.
# we want 'Xyy' where X is number to move and yy is direction.
sub nq_navi_move {
  my $self = shift;

  my ($count, $dir) = $_[0] =~ /(\d+)([a-z]{1,2})/;
  print "$0: nq_move: ('$count', '$dir') -- parameter error\n"
    and return unless ($count and $dir);

  my $response;
  my %dirs;
  @dirs{ qw{ nw n ne w e sw s se } } = ( 1 .. 8 );

  $dir = $dirs{ $dir };

  my $url = NQ_URL."?action=move&movedir=$dir";

  for( 1 .. $count) {
    $response = $self -> get_url( $url );

    if ( $self -> {objects} -> {NQ} -> {DEBUG} )
      { write_file("tmp", $response) }

    if ( $self -> nq_is_battle( $response ) ) {
      print "Attack! (after ", $_+1, " moves)\n";
      $response = $self -> nq_battle_enter( $self -> get_url() );
    }
  }
  $self -> nq_look( $response ) unless ( $self -> {objects} -> {NQ} -> {SCRIPT} );

  return $response;
}

# sets normal navigational mode
sub nq_navi_mode_normal {
  my $self = shift;
  $self -> nq_navi_mode( 1 );
}

# sets sneak navigational mode
sub nq_navi_mode_sneak {
  my $self = shift;
  $self -> nq_navi_mode( 3 );
}

# sets hunting navigational mode
sub nq_navi_mode_hunt {
  my $self = shift;
  $self -> nq_navi_mode( 2 );
}

# sets the navigational hunting mode
# should only be used via:
#   nq_navi_mode_normal()
#   nq_navi_mode_sneak()
#   nq_navi_mode_hunt()
sub nq_navi_mode {
  my $self = shift;
  my $mode = shift || 1;
  my $url;

  if ( $mode == 2 ) {
    print BLUE, " <> ", RESET, "Entering hunt mode\n";
    $url = NQ_URL."?movetype=2";
  } elsif ( $mode == 3 ) {
    print BLUE, " <> ", RESET, "Entering sneak mode\n";
    $url = NQ_URL."?movetype=3";
  } else {
    print BLUE, " <> ", RESET, "Entering normal mode\n";
    $url = NQ_URL."?movetype=1";
  }

  $self -> get_url( $url );
}

#
# -- end Navi section --
#

1;
