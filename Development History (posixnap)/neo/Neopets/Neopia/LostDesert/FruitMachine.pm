package Neopets::Neopia::LostDesert::FruitMachine;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::LostDesert::FruitMachine - Fruit Machine interface

=head1 SYNOPSIS

  # create a machine object and use it

  use Neopets::Agent;
  use Neopets::Neopia::LostDesert::FruitMachine;

  my $agent = Neopets::Agent -> new();
  my $machine = Neopets::Neopia::LostDesert::FruitMachine -> new(
    { agent => \$agent } );

  my $result = $machine -> spin();

=head1 ABSTRACT

This module visits the Fruit Machine in the lost desert.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant MACHINE_URL => 'http://www.neopets.com/desert/fruitmachine.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $machine = Neopets::Neopia::LostDesert::FruitMachine->new;

This constructor takes hash arguments and
returns a machine object.  Optional arguments
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

=item $machine -> spin();

This method spins the fruit machine
and returns the result.

=cut

sub spin {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  $agent -> get(
    { url => 'http://www.neopets.com/desert/fruitmachine.phtml' } );

  my $response = 
      $agent -> post(
        { url => 'http://www.neopets.com/desert/fruitmachine2.phtml' } );#,
          #referer => MACHINE_URL } );

  return unless $response;

  if ( $response =~ /You have already played today/ ) {
      return "You have already spun";
  }

  my ( $reward ) = $response =~
      m!border='0'><p align='center'>(.*?)<center>!s;

  # XXX: temporary, needs help
  debug( $response ) unless $reward;

  $reward =~ s/<.*?>//g;
  $reward =~s/\n//g;

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
