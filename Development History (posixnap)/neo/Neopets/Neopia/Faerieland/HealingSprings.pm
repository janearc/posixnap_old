package Neopets::Neopia::Faerieland::HealingSprings;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::Faerieland::HealingSprings - Healing Springs interface

=head1 SYNOPSIS

  # create a spring object and heal
  # with it

  use Neopets::Agent;
  use Neopets::Neopia::Faerieland::HealingSprings;

  my $agent = Neopets::Agent -> new();
  my $spring = Neopets::Neopia::Faerieland::HealingSprings -> new(
    { agent => \$agent } );

  my $response = $spring -> heal();

=head1 ABSTRACT

This module sends the currently active pet
to the Healing Springs in Faerieland.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant SPRINGS_URL => 'http://www.neopets.com/faerieland/springs.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $spring = Neopets::Neopia::Faerieland::HealingSprings -> new;

This constructor takes hash arguments and
returns a spring object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  debug => $debug  (true or false)

=cut

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
      AGENT => $agent,
    },
  }, $this;
}

=item $spring -> heal();

This method attempts to heal the current
pet at the healing springs.  The result
is returned.

=cut

sub heal {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {AGENT} };

  my $response = 
      $agent -> post(
        { url => SPRINGS_URL,
          referer => SPRINGS_URL,
          params => { type => 'heal' }, } );

  if ( $response =~ /not fully restored yet/ ) {
      return "You can only come every 30 minutes";
  }

  my ( $reward ) = $response =~
      m/width=150 height=150 border=0><p><b>(.*?)<form/;
  $reward =~ s/<.*?>//g;

  return "$reward";
}

1;

=back

=head1 SUB CLASSES

None.

=head1 COPYRIGHT

Copyright 2002

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

=head1 LICENSE

Please see the enclosed LICENSE file for licensing information.

=cut
