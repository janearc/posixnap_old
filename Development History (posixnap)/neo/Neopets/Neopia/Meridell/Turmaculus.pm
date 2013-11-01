package Neopets::Neopia::Meridell::Turmaculus;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::Meridell:Turmaculus - A Turmaculus module

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=cut

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

our %methods = (
  'stick'  => 1,
  'bell'   => 2,
  'kick'   => 3,
  'sing'   => 4,
  'dance'  => 5,
  'blow'   => 6,
  'sneeze' => 7,
  'water'  => 8,
  'scream' => 9,
  'pots'   => 10,
);


BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $object = Neopets::Template->new;

This constructor takes hash arguments and
returns a turmaculus object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  pet   => \$pet   (takes a Neopets::Pet ref)
  debug => $debug  (true or false)


=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
  my ( $args ) = @_;

  my $agent = $args -> {agent};
  my $pet = $args -> {pet};
  $DEBUG = $args -> {debug};

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }
  unless ( $pet ) #create a pet object if necessary
    { $pet = \Neopets::Pet -> new( { agent => \$agent, debug => $DEBUG } )
        || die "$0: unable to create pet object\n" }

  return bless {
    objects => {
      agent => $agent,
      pet   => $pet,
    },
  }, $this;
}

=item $turmaculus -> wake();

Attempts to wake the turmaculus.
Takes a hashref argument:

  wake(
    { method => 'stick' } );

Possible options are:
  stick
  bell
  kick
  sing
  dance
  nose
  sneeze
  water
  scream
  pots

Defaults to ringing a bell.

=cut

sub wake {
  my $self = shift;
  my ( $args ) = @_;

  my $agent = ${ $self -> {objects} -> {agent} };
  my $pet = ${ $self -> {objects} -> {pet} };

  my $method = $methods{ $args -> {method} } || 2;
  my $active_pet = $pet -> current_pet();

  my $response = $agent -> get(
    { url => "http://www.neopets.com/medieval/process_turmaculus.phtml?type=wakeup&active_pet=$active_pet&wakeup=$method",
      referer => "http://www.neopets.com/medieval/turmaculus.phtml",
      no_cache => 1,
    } );

  if ( $response =~ /could not wake him/ ) {
    return 'could not wake him';
  }

  return $response;
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
