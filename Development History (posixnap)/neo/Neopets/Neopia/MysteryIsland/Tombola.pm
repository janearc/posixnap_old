package Neopets::Neopia::MysteryIsland::Tombola;

# XXX: this doesn't work so well...

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

use constant TOMBOLA_URL => 'http://www.neopets.com/island/tombola.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

sub new {
  my $that = shift;
  my $this = ref( $that ) || $that;
  my ( $args ) = @_; 

  my $agent = $args -> {agent};
  $DEBUG = $args -> {debug};

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }

  return bless { 
    objects => {
      agent => $agent, 
    },
  }, $this;
}

sub grab {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = 
      $agent -> get( { url => TOMBOLA_URL } );

  if ( $response =~ /out of cash/ ) {
    return "out of cash..";
  }


  $response = $agent -> get( { url => 'http://www.neopets.com/island/tombola2.phtml',
                               referer => TOMBOLA_URL } );
 
  if ( $response =~ /WINNER/ ) {
    return "you won something";
    my ( $prize ) = $response =~ m/(You Win \d+ Neopoints)/;
    print "$prize\n";
    if ( $response =~ /plus the following item/ ) {
      return "and some item";
    }

  } elsif ( $response =~ /one Tombola free spin/ ) {
    return "you have spun today already";
  } else {
    return "nothing won";
  }
}

1;
