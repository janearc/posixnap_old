#!/usr/bin/perl

package Neopets::Games::NeoQuest;

# -- RECOMMENT --
#     more

# todo:
#   display found items after battle
#   modularisize
#   combine navi and navi_passage
#   always pass $response
#     testing
#   impliment nq_is_map
#   interface for talking
#   interface for items
#     item prompt

use warnings;
use strict;
use File::Slurp;
use Term::ANSIColor qw/:constants/;
use Data::Dumper;
use Neopets::Agent;
use Neopets::Games::NeoQuest::Battle;
use Neopets::Games::NeoQuest::Look;
use Neopets::Games::NeoQuest::Navi;
use Neopets::Games::NeoQuest::Status;
use Neopets::Games::NeoQuest::Talk;

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

# debug flag
our $DEBUG = 0;

$|++;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

END { -e "tmp" and unlink "tmp" }

use constant NQ_URL => 'http://www.neopets.com/games/neoquest/neoquest.phtml';

sub new {
  my $that = shift;
  my $this = ref( $that ) || $that;

  my $agent = shift || die "Neopets::Games::NeoQuest->new must take a Neopets::Agent object\n";

  my %NQ = (
    INTERACTIVE => 1,
    SCRIPT      => 0,
    NAME        => '',
    NO_FETCH    => 0,
  );

  return bless {
    objects => {
      NQ => \%NQ,
      AGENT => $agent,
    },
  }, $this;
}

#
# -- Main section --
#

sub nq_main {
  my $self = shift;

  # Declaring and reusing $response here would mean
  # fewer lookups to do, however it doesn't work and
  # i don't know why.  the variable is good here, but
  # after being passes, Dumper gives me:
  # $VAR1 = \'HTTP::Response=HASH(0x382e94)';
  #my $response = $self -> get_url();

  print BLUE, "> ", RESET;
  while (<>) {
    chomp (my $input = $_);
    my @cmds = split ' ', $input;
    my $cmd =  shift @cmds;

		# this is begging for a dispatch hash. aja

    my %dispatch = (
      l      => \&nq_look,

      m      => \&nq_navi,
      pass   => \&nq_navi_passage,
      hunt   => \&nq_navi_mode_hunt,
      sneak  => \&nq_navi_mode_sneak,
      norm   => \&nq_navi_mode_normal,

      t      => \&nq_talk,

      i      => \&nq_switch_battle_interactive,
      script => \&nq_switch_script,
      d      => \&nq_switch_debug,

      s      => \&nq_status_player,

      b      => \&nq_battle_enter,

      h      => \&nq_main_help,
    );

    if ( $cmd ) {
      if ( $dispatch{ $cmd } )
        # Again, see above comment about $response and flubber
	# i would love to do this, but don't know why it doesn't work
        #{ $response = $dispatch{ $cmd } -> ( $self,  join ' ', @cmds, $response ) }
	{ $dispatch{ $cmd } -> ( $self,  join ' ', @cmds ) }
      else
        { print "Huh?\n" }
    }
		
    print BLUE, "> ", RESET;
  }
}

# displays the help
sub nq_main_help {
  my $self = shift;
  print "->	b, l, m #dir, pass, t (name)\n";
  print "		s, hunt | sneak | norm,\n";
  print "		h, i [0|1], script 1\n";
  print "		d\n";
}

#
# -- end Main section --
#

#
# -- Switch section --
#

# toggle script mode
# if shift, script mode is set
# cannot be unset
sub nq_switch_script {
  my $self = shift;
  my $scrip = shift;

  if ( $scrip ) {
    print "-> Setting script mode\n";
    $self -> {objects} -> {NQ} -> {INTERACTIVE} = 0;
    $self -> {objects} -> {NQ} -> {SCRIPT} = 1;
  }
}

# toggle debug mode
# if shift, debug is set
sub nq_switch_debug {
  my $self = shift;
  my $debug = shift;

  if ( $debug ) {
    print "-> Setting debug\n";
    $DEBUG = 1;
  } else {
    print "-> Unsetting debug\n";
    $DEBUG = 0;
  }
}

# toggle interactive mode
# if shift, interactive mode set
sub nq_switch_battle_interactive {
  my $self = shift;
  my $inter = shift;

  if ( $inter ) {
    print "-> Setting interactive battle mode\n";
    $self -> {objects} -> {NQ} -> {INTERACTIVE} = 1;
  } else {
    print "-> Setting automatic battle mode\n";
    $self -> {objects} -> {NQ} -> {INTERACTIVE} = 0;
  }
}

#
# -- end Switch section
#

#
# -- Test section --
#

# return true if character is in a fight
# takes $response (HTTP::Response, optional)
sub nq_is_battle {
  my $self = shift;

  my $response = shift || $self -> get_url();

  if ( ($response =~ 'You are attacked by' )
    or ($response =~ 'Do nothing' ) 
    or ($response =~ 'You defeated' ) 
    or ($response =~ 'You were defeated by a') )
       { return 1 }
  else { return 0 };
}

# return true if character is on map
# -- this does nothing yet, fix this --
sub nq_is_map { return 1; }

#
# -- end Test section --
#

#
# -- Tool section --
#  will be removed at some point...

# return the HTTP::Response object recieved from the url
# takes $url (optional)
# defaults to NQ_URL constant
sub get_url {
  my $self = shift;

  my $url = shift || NQ_URL;
  my $agent = ${ $self -> {objects} -> {AGENT} };

  debug( "getting $url" );
  $self -> {objects} -> {NQ} -> {NO_FETCH} and exit 0;

  return $agent -> get( { url => $url, no_cache => 1 } );
}

#
# -- end Tool section --
#

1;

=head1 NAME

Neopets::Games::NeoQuest - Interface to NeoQuest

=head1 SYNOPSIS

  use Neopets::Agent;
  use Neopets::Games::Neoquest;

  my $agent = Neopets::Agent -> new();
  my $quest = Neopets::Games::Neoquest -> new( \$agent );

  $quest -> nq_navi_mode_hunt();
  $quest -> mq_main();

=head1 ABSTRACT

This module provides an interface to the Neopets game,
NeoQuest ( http://www.neopets.com ).  It is designed to
offer a different interface aside from the standard
browser interface.  It is capable of running a client
application, but also offers all functions to allow
the user to design a different interface.

This module does not exist to allow users to cheat,
it is simply an alternative interface.  We do not
believe use of this module gives users an upperhand
in any way.

=head1 METHODS

The following methods are provided:

$quest = Neopets::Games::NeoQuest->new( \$agent );
    The constructor takes only one argument of type
    Neopets::Agent.

$quest -> nq_main();
    This function runs the client provided in this
    module.  It includes a text interface for
    navigation and battle.  Will display the map
    to terminal in a color grid layout.

=head1 SUB CLASSES

None.

=head1 COPYRIGHT

Copyrite 2002

Neopets::* are the combined works of Alex Avriette and
Matt Harrington.

Matt Harrington <narse@underdogma.net>
Alex Avriette <avriettea@speakeasy.net>

The perl5.5 vs perl < 5.5 build process is stolen with
permission from sungo and the POE team (poe.perl.org),
mostly verbatim.

I suppose we should thank the Neopets people too for
making such a thoroughly enjoyable site. Maybe one day
they will make a text interface for their site so we
wouldnt have to code an API around the LWP:: and 
HTTP:: modules, but probably not. Until then...

