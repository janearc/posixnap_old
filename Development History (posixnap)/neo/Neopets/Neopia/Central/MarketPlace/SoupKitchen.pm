package Neopets::Neopia::Central::MarketPlace::SoupKitchen;

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Neopia::Central::MarketPlace::SoupKitchen - Soup Kitchen interface

=head1 SYNOPSIS

=head1 ABSTRACT

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

=item $kitchen = Neopets::Neopia::Central::MarketPlace::SoupKitchen->new;

This constructor takes hash arguments and
returns a kitchen object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  debug => $debug  (true or false)

=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
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

=item $kitchen -> feed( $pet );

This attempts to feed the $pet
(Neopets::Pet::Simple).  Returns
true if sucecss.

=cut

sub feed {
  my $self = shift;
  my $pet = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  die "No pet object supplied\n" unless $pet;
  die "Pet object must have 'name' attribute\n" unless my $name = $pet -> name();

  my $page = $agent -> get(
    { url => "http://www.neopets.com/get_soup.phtml?pet_name=$name",
      referer => 'http://www.neopets.com/soupkitchen.phtml' } );

  return $page =~ /$name says/;
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
