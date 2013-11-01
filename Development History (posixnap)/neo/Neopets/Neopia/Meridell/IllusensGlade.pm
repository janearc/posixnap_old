package Neopets::Neopia::Meridell::IllusensGlade;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::Shops;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Neopia::Meridell::IllusensGlade - An Illusen interface

=head1 SYNOPSIS

  # create an illusen object and help

  use Neopets::Agent;
  use Neopets::Shop;
  use Neopets::Neopia::Meridell::IllusensGlade;

  my $agent = Neopets::Agent -> new();
  my $shop = Neopets::Shops -> new( { agent => \$agent } );
  my $illusen =
    Neopets::Neopia::Meridell::IllusensGlade -> new(
      { agent => \$agent,
        shop => \$shop,
      } );

  $illusen -> help();

=head1 ABSTRACT

This module is used for interacting with Illusen
found in Illusens Glade, Meridell.

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

=item $object = Neopets::Neopia::Meridell::IllusensGlade->new;

This constructor takes hash arguments and
returns a illusen object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  shop  => \$shop  (takes a Neopets::Shop ref)
  debug => $debug  (true or false)


=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
  my ( $args ) = @_;

  my $agent = $args -> {agent};
  my $shop = $args -> {shop};
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

=item $illusen -> begin();

This method attempts to get
an item request from Illusen.
Returns an item name if possible.
Returns 'not ready' if Illusen
is not ready for a quest.

=cut

sub begin {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get( { url => 'http://www.neopets.com/medieval/earthfaerie.phtml' } );

  if ( $response =~ /I am not ready/ ) {
    return "not ready";
  }

  $response = $agent -> get(
    { url => 'http://www.neopets.com/medieval/process_earthfaerie.phtml',
      referer => 'http://www.neopets.com/medieval/earthfaerie.phtml',
      params => { type => 'accept', username => $agent -> username() },
    } );

  my ( $item ) = $response =~ m!Where is my <b>(.*?)</b>!;

  return $item ? $item : undef;
}

=item $result = $illusen -> finish();

If you have the required item,
this method will finish a quest.
Returns true if successful.

sub finish {
  my $self = shift;

  my $response = $agent -> get(
    { url => 'http://www.neopets.com/medieval/process_earthfaerie.phtml',
    referer => 'http://www.neopets.com/medieval/process_earthfaerie.phtml',
    params => { type => 'finished' },
    } );

  if ( $response =~ /Congratulations/ )
    { return 1 }

  return 0;
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
