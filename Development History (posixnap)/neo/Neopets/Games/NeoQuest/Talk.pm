package Neopets::Games::NeoQuest::Talk;

use constant NQ_URL => 'http://www.neopets.com/games/neoquest/neoquest.phtml';

use strict;
use warnings;
use Term::ANSIColor qw/:constants/;
use Exporter;
use Data::Dumper;
use Neopets::Games::NeoQuest::Look;

use vars qw/@ISA @EXPORT $VERSION/;

@EXPORT = qw/nq_talk nq_talk_shell nq_talk_get nq_talk_npc_get nq_talk_user_get nq_talk_help/;
@ISA = qw/Exporter/;
$VERSION = 0.01;

#
# -- Talk section --
#

sub nq_talk {
  my $self = shift;
  my $name = shift;


  my $response = $self -> get_url();

  my %people = %{ $self -> nq_look_talk_get( $response ) };

  if ( $people{ $name } ) {
    $response = $self -> nq_talk_shell( $name,
        $self -> get_url( 'http://www.neopets.com/games/neoquest/'.$people{ $name } ) );
  } else {
    print "There is no one here by that name\n";
  }

  return $response;
}

sub nq_talk_shell {
  my $self = shift;
  my $name = shift;
  my $response = shift || $self -> get_url();

  my @user_text = @{ $self -> nq_talk_get( $response ) };

  print GREEN, "> ", RESET;
  while( <> ) {
    chomp (my $input = $_);

    if ( $input ) {

        # leave the conversation
      if ( $input eq 'leave' ) {
        return;
	# test if chat command (0-9)
      } elsif ( $input =~ m/^\d+$/ ) {
        if ( $user_text[$input-1] ) {
	  $response = $self -> get_url( 'http://www.neopets.com/games/neoquest/'.$user_text[$input-1]->{link} );
        } else {
	  print "No matching response\n";
        }
      } else { # not command
        print "What?\n";
	$self -> nq_talk_help();
      }

    @user_text = @{ $self -> nq_talk_get( $response ) };

    } # no $input

    print GREEN, "> ", RESET;
  }
}

# print help for talking
sub nq_talk_help {
  print "0-9 (for preset responses), leave\n";
}

# get and display the talk texts
# returns an array of hashes of user options
sub nq_talk_get {
  my $self = shift;
  my $response = shift || $self -> get_url();

    # get and print npc talk
  print "\n";
  print "$_\n" for @{ $self -> nq_talk_npc_get($response) };
  print "\n";

    # get and print user talk options
  my @user_text = @{ $self -> nq_talk_user_get($response) };
  if ( @user_text ) {
    print "Chat options (type number)\n";
    for ( 1 .. @user_text )
      { print "\t$_ : ".$user_text[$_-1]->{text}."\n" }
  }

  return \@user_text;
}


# return an array of things an npc has to say
sub nq_talk_npc_get {
  my $self = shift;
  my $response = shift;

  my @npc_text = $response =~ m/<BR>?\W+([\w]+ says, [^<]+)/g; 

  return \@npc_text;
}

# return an array of hashes of options for the user to say
sub nq_talk_user_get {
  my $self = shift;
  my $response = shift;

  my @text = $response =~ m/Say, "<A HREF="([^"]+)[^>]+>([^<]+)/g;

  my @user_text;
  while ( @text ) {
    @user_text = map { { text => $_->[1],
                         link => $_->[0], } } [ shift @text, shift @text ];
  }

  return \@user_text;
}


1;
