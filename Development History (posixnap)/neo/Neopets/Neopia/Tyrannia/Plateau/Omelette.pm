package Neopets::Neopia::Tyrannia::Plateau::Omelette;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::Tyrannia::Plateau::Omelette - Omelette fetcher

=head1 SYNOPSIS

  use Neopets::Agent;
  use Neopets::Neopia::Tyrannia::Plateau::Omelette;

  my $agent = Neopets::Agent -> new();
  my $omelette =
      Neopets::Neopia::Tyrannia::Plateau::Omelette -> new(
        { agent => \$agent } );

  $omelette -> get();

=head1 ABSTRACT

This module gets a piece of the Tyrannian omelette
(see Neopets::Agent).  It features only one method
as the omelette isn't very exciting.

This module requires that a variable NP_HOME be set in order to function.
This should be the path to a writable directory in which this toolkit
can store information.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant OMELETTE_URL => 'http://www.neopets.com/prehistoric/omelette.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $omelette = Neopets::Neopia::Tyrannia::Plateau::Omelette->new;

This constructor takes hash arguments and
returns a omelette object.  Optional arguments
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

=item $omelette -> get;

This method gets a piece of the omelette and
prints the success.  Which kind of omelette
was taken is unknown as it is not announced
at the time of the thieft.

=cut

sub get {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = 
      $agent -> post(
        { url => OMELETTE_URL,
          referer => OMELETTE_URL,
          params => { type => 'get_omelette' }, } );

  if ( $response =~ /one slice per day/ ) {
    return "You already had a slice";
  } elsif ( $response =~ /manage to take a slice/ ) {
    return "You got a slice";
  }
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
