package Neopets::Games::NeoQuest::Status;

use constant NQ_URL => 'http://www.neopets.com/games/neoquest/neoquest.phtml';

use strict;
use warnings;
use Term::ANSIColor qw/:constants/;
use Exporter;
use Neopets::Debug;

use vars qw/@ISA @EXPORT $VERSION/;

@EXPORT = qw/nq_status_player nq_status_opponent nq_status/;
@ISA = qw/Exporter/;
$VERSION = 0.01;

#
# -- Status section --
#

# outputs player status
# takes $response (HTTP::Response, optional)
# returns HTTP::Response
sub nq_status_player {
  my $self = shift;
  my $response = shift || $self -> get_url();
  return $self -> nq_status($response, 0);
}

# outputs opponent status
# takes $response (HTTP::Response, optional)
# returns HTTP::Response
sub nq_status_opponent {
  my $self = shift;
  my $response = shift || $self -> get_url();
  return $self -> nq_status($response, 1);
}

# prints status, used by:
#  nq_status_player()
#  nq_status_opponent()
# displays either there player status
#  or the opponent status when in battle
#  defaults to player if unspecified
# takes $response (HTTP::Response, optional),
#  $opponent (true if display opponent status, optional)
# returns HTTP::Response
sub nq_status {
  my $self = shift;
  my $response = shift || $self -> get_url();
  my $opponent = shift || 0;

  debug( "opponent status requested when not in fight" )
    unless ($opponent <= $self -> nq_is_battle($response));

  # get the right line and chop it up and display it
  if ($opponent) {
    my @bigjunk = grep { /Health:/ } split '\n', $response;
    my @junk = split ' ', $bigjunk[2];

    my ( $level ) = $junk[11] =~ m/<B>(.*)<\/B>/;
    my ( $curhealth ) = $junk[3] =~ m/<B>(.*)<\/B>/;
    my ( $tothealth ) = $junk[3] =~ m/<\/B>\/(.*)/;

    @junk = split '<B>', $bigjunk[0];
    my ( $name ) = $junk[7] =~ m/(.*)<\/B>/;

    print " # Name  : $name\n # Level : $level\n # Health: $curhealth/$tothealth\n";
  } else {
    my @junk =  grep { /Name:/ } split '\n', $response;
    @junk = split ' ', $junk[0];

    my ( $name ) = $junk[1] =~ m/<B>(.*)<\/B>/;
    my ( $level ) = $junk[4] =~ m/<B>(.*)<\/B>/;
    my ( $curhealth ) = $junk[8] =~ m/<B>(.*)<\/B>/;
    my ( $tothealth ) = $junk[8] =~ m/<\/B>\/(.*)<\/FONT>/;

    print " | Name  : $name\n | Level : $level\n | Health: $curhealth/$tothealth\n";
  }

  return $response;
}

#
# -- end Status section --
#

1;
