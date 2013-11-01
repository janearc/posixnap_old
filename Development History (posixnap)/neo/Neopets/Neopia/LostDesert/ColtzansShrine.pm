package Neopets::Neopia::LostDesert::ColtzansShrine;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::LostDesert::ColtzansShrine - Coltzan's Shrine interface

=head1 SYNOPSIS

  # create a shrine object and use it

  use Neopets::Agent;
  use Neopets::Neopia::LostDesert::ColtzansShrine;

  my $agent = Neopets::Agent -> new();
  my $shrine = Neopets::Neopia::LostDesert::ColtzansShrine -> new(
    { agent => \$agent } );

  my $result = $shrine -> visit();

=head1 ABSTRACT

This module visits Coltzan's Shrine in the Lost Desert with
the active pet.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant SHRINE_URL => 'http://www.neopets.com/desert/shrine.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $shrine = Neopets::Neopia::LostDesert::ColtzansShrine->new;

This constructor takes hash arguments and
returns a shrine object.  Optional arguments
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
      agent => $agent,
    },
  }, $this;
}

=item $shrine -> visit();

This method visits the shrine with
the currently active neopet and
returns the results.

=cut

sub visit {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  $agent -> get(
    { url => SHRINE_URL,
      referer => 'http://www.neopets.com/desert/index.phtml'
    } );

  my $response = 
      $agent -> post( { url => SHRINE_URL,
                       referer => SHRINE_URL,
                       params => { type => 'approach' } } );

  my ( $reward ) = $response =~
      m!shrine_.\.gif' width=200 height=200 border=0>(.*?)<img!s;

  # XXX: temporary debug
  debug( $response ) unless $reward;

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
