package Neopets::Games::Cliffhanger;

use warnings;
use strict;
use File::Slurp;
use Neopets::Agent;
use Neopets::Debug;

use constant PROC_CLIFF_URL => 'http://www.neopets.com/games/cliffhanger/process_cliffhanger.phtml';
use constant CLIFF_URL => 'http://www.neopets.com/games/cliffhanger/cliffhanger.phtml';

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

  my $agent = shift || die "Neopets::Games::Cliffhanger->new must take a Neopets::Agent object\n";

  my @words;

  return bless {
    objects => {
      WORDS => \@words,
      AGENT => $agent,
    },
  }, $this;
}

sub begin {
  my $self = shift;
  my $skill = shift || 1;

  my $agent = ${ $self -> {objects} -> {AGENT} };

  $agent -> get( { url =>  PROC_CLIFF_URL."?start_game=true&game_skill=$skill",
                   referer => CLIFF_URL } );
  $agent -> get( { url => CLIFF_URL, referer => CLIFF_URL } );
};

sub find_solution {
  my $self = shift;
  
  my $agent = ${ $self -> {objects} -> {AGENT} };

  my $response = shift || $agent -> get( { url => CLIFF_URL } );

  my @html = grep { /<b> _ <\/b>/ } split '\n', $response;
  @html = split ' ', $html[0];

  my @words;
  my $counter = 0;
  foreach (@html) {
    if ( $_ eq '_' ) {
          $counter++;
    } elsif ( ($_ eq '&nbsp;') or ($_ eq '</b><br><b>') ) {
        push @words, $counter;
	$counter = 0;
    }
  }
  if ($counter) { push @words, $counter; }

  my $reg = join '\\W', map { '.'x$_ } @words;
  $reg = "^$reg\$";
  my ( $answer ) = grep { /^$reg$/ } @{ $self -> {objects} -> {WORDS} };

  return $answer;
}

sub solve {
  my $self = shift;
  my $answer = shift;

  unless ( $answer ) { fatal( "requires an answer" ) }

  my $agent = ${ $self -> {objects} -> {AGENT} };

  my $response = $agent -> get( { url => PROC_CLIFF_URL."?solve_puzzle=$answer",
                                  referer => CLIFF_URL } );
}

sub load_words {
  my $self = shift;

  my @words = read_file($ENV{NP_HOME}."/cliffhanger.txt");

  $self -> {objects} -> {WORDS} = \@words;
}


1;
