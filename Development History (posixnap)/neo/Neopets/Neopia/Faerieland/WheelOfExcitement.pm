package Neopets::Neopia::Faerieland::WheelOfExcitement;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::Common::Wheel;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::Faerieland::WheelOfExcitement - Wheel of Exitement interface

=head1 SYNOPSIS

  # create a wheel object and spin it

  use Neopets::Agent;
  use Neopets::Neopia::Faerieland::WheelOfExcitement;

  my $agent = Neopets::Agent -> new();
  my $wheel = Neopets::Neopia::Faerieland::WheelOfExcitement -> new(
    { agent => \$agent } );

  my $prize = $wheel -> spin();

=head1 ABSTRACT

This module allows for manipulation of the Neopets Wheel
of Excitement found in Faerieland.  It has only one
method: spin() which is prety self explanatory.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $wheel = Neopets::Neopia::Faerieland::WheelOfExcitement->new;

This constructor takes hash arguments and
returns a wheel object.  Optional arguments
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

  $DEBUG and $Neopets::Common::Wheel::DEBUG = 0;

  return bless {
    objects => {
      AGENT => $agent,
    },
  }, $this;
}

=item $wheel -> spin();

This method spins the wheel and returns
the result in a scalar.

=cut

sub spin {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {AGENT} };

  debug( "$0: spin: spinning\n" );

  return common_spin(
    $agent,
    'http://www.neopets.com/faerieland/wheel.phtml',
    'http://www.neopets.com/faerieland/wheel2.phtml',
    'http://www.neopets.com/faerieland/wheel3.phtml'
  );
}

1;

=back

=head1 SUB CLASSES

See Neopets::Config::

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
