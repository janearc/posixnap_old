package Neopets::Games::PoogleSolitaire;

# Written by Dan Risacher
# This is a bit of a hack, to get me up to speed on writing Neopets:: modules.

# Needs to be cleaned up.  Unfortunately this is hard to do because NP has locked me out from playing PS.

use warnings;
use strict;
use File::Slurp;
use Neopets::Agent;

use constant POOGLE_URL => 'http://www.neopets.com/games/poogle_solitaire/poogle_solitaire.phtml';
use constant PROC_POOGLE_URL => 'http://www.neopets.com/games/poogle_solitaire/process_poogle_solitaire.phtml';
use constant NEW_POOGLE_URL => 'http://www.neopets.com/games/poogle_solitaire/process_poogle_solitaire_new.phtml';
use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

my %crosswalk = ( # maps cells to pegs
    3 => 1, 4 => 2, 5 => 3, 10 => 4, 11 => 5, 12 => 6, 15 => 7, 16 => 8, 17 => 9, 18 => 10, 19 => 11, 20 => 12, 21 => 13, 22 => 14, 23 => 15, 24 => 16, 25 => 17, 26 => 18, 27 => 19, 28 => 20, 29 => 21, 30 => 22, 31 => 23, 32 => 24, 33 => 25, 34 => 26, 35 => 27, 38 => 28, 39 => 29, 40 => 30, 45 => 31, 46 => 32, 47 => 33 );
my %reverse_crosswalk =  # maps pegs to cells, obviously
    map { ( $crosswalk{$_}, $_ ) } ( keys %crosswalk ) ; 

#for my $k (sort keys %reverse_crosswalk) {
#    print "$k $reverse_crosswalk{$k}, ";
#}

sub new {
  my $that = shift;
  my $this = ref( $that ) || $that;

  my $agent = shift || die "Neopets::Games::PoogleSolitaire->new must take a Neopets::Agent object\n";

  my @cells;

  return bless {
    objects => {
      CELLS => \@cells,
      AGENT => $agent,
    },
  }, $this;
}

sub begin {
  my $self = shift;
  my $agent = ${ $self -> {objects} -> {AGENT} };

  $agent -> get( { url => NEW_POOGLE_URL, referer => NEW_POOGLE_URL } );
  $agent -> get( { url => POOGLE_URL, referer => POOGLE_URL } );
};

sub scan {
    my $self = shift;
    my $agent = ${ $self -> {objects} -> {AGENT} };
    my $response = $agent -> get( { url => POOGLE_URL, referer => POOGLE_URL, no_cache => 1} );
    my %res = ();
    my (@html_cells) = $response =~ 
	m/<b\>[0-9]+<\/b><\/font><a href="javascript:;" onClick=\"set_state\([0-9]+,(?:true|false)\)/sg ;
    for my $h (@html_cells) {
	my ($peg, $cell, $state) = $h =~
	    m/([0-9]+)<\/b><\/font><a href="javascript:;" onClick=\"set_state\(([0-9]+),(true|false)\)/ ;
	$res{$peg} = $state;
    }
    return \%res;
}

sub move {
    my $self = shift;
    my ($from_peg, $to_peg) = @_;
    my $agent = ${ $self -> {objects} -> {AGENT} };
    my $response = $agent -> get( { url =>  PROC_POOGLE_URL."?from=$reverse_crosswalk{$from_peg}&to=$reverse_crosswalk{$to_peg}",
                                    referer => POOGLE_URL,
                                    no_cache => 1 } );
}

my $solution = ("19-17,30-18,27-25,13-27,18-30,33-25,24-26,31-33,28-30,33-25,16-18,18-30,".
		"27-25,30-18,14-16,16-28,21-23,28-16,9-23,7-9,4-16,23-9,10-8,12-10,3-11,1-3,".
		"18-6,3-11,11-9,8-10,5-17");

sub solve_canned {
    my $self = shift;
    my @moves = split(",", $solution);
    for my $m (@moves) {
	my ($from_peg, $to_peg) = $m =~ m/([0-9]+)-([0-9]+)/;
	print "intending to move from peg $from_peg ($reverse_crosswalk{$from_peg}) to peg $to_peg ($reverse_crosswalk{$to_peg})\n";
	$self->move($from_peg, $to_peg);
    }
    $self->scan;
}
1;
