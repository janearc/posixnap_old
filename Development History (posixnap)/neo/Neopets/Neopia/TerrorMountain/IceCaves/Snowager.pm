package Neopets::Neopia::TerrorMountain::IceCaves::Snowager;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::TerrorMountain::IceCaves::Snowager - Snowager interface.

=head1 ABSTRACT

  # create a worm object and use it

  use Neopets::Agent;
  use Neopets::Neopia::TerrorMountain::IceCaves::Snowager;

  my $agent = Neopets::Agent -> new();
  my $worm = Neopets::Neopia::TerrorMountain::IceCaves::Snowager -> new(
    { agent => \$agent };

  $worm -> steal();;

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant SNOWAGER_URL => 'http://www.neopets.com/winter/snowager.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $worm = Neopets::Neopia::TerrorMountain::IceCaves::Snowager->new;

This constructor takes hash arguments and
returns a worm object.  Optional arguments
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

=item $worm -> steal();

This method attempts to steal an
item from the snowager.  The
success is returned.

=cut

sub steal {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get(
    { url => SNOWAGER_URL,
      referer => 'http://www.neopets.com/winter/icecaves.phtml' } );

  if ( $response =~ /The Snowager is awake/ ) {
    return "The Snowager is awake";
  }

  $response =
      $agent -> get( { url => 'http://www.neopets.com/winter/snowager2.phtml',
                       referer => SNOWAGER_URL } );

  if ( $response =~ /Come back later/ ) {
    return "You'v gotten your booty today already";
  } elsif ( $response =~ /fires an icy blast/ ) {
    return "Snowager 23423 : You 0";
  } elsif ( $response =~ /looks straight at you/ ) {
    return "You got nothing";
  } else {
    my ( $reward ) = $response =~ m!iceworm_[^\.]+.gif' width=150 height=150 border=0><p><b>(.*?)</center>!i;
    $reward =~ s/<.*?>//g;
    if ( $reward ) {
        print "$reward\n";
    } else {
        print "$response\n";
    }
    return $reward ? $reward : "something unknown happened";
  }
}

1;

=back

=head1 SUB CLASSES

none.

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
