package Neopets::Inventory;

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Inventory - Inventory Manipulation

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

=item $inv = Neopets::Inventory -> new;

This constructor takes hash arguments and
returns an inventory object.  Optional arguments
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

=item @inventory = @{ $inv -> list() };

Lists all items found in the inventory.
Returns an array of Neopets::Item::Simple
objects;

=cut

sub list {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $page = $agent -> get({ url => 'http://www.neopets.com/quickstock.phtml' });

  my @item_list = $page =~ m!<td width=220 align=left bgcolor='\#ffffcc'>([^<]+)</td>!g;

  my @inventory = qw//;
  foreach my $name ( @item_list ) {
    my $item = Neopets::Item::Simple -> new(
      { name => $name } );
    push @inventory, $item;
  }

  return \@inventory;
}

=item $inv -> give( { item => $item, friend => $friend } );

This method attempts to give the $item
to the $friend where $item is a
Neopets::Item::Simple and $friend is
a string name.

=cut

sub give {
  my $self = shift;
  my ( $args ) = @_;

  my $agent = ${ $self -> {objects} -> {agent} };
  my $item = $args -> {item};
  my $friend = $args -> {friend};

  fatal( "Must supply both friend => and item => hashref args" )
    unless( $item and $friend );

  fatal( "item msut have an \$id field" )
    unless( $item -> id() );

  my $page = $agent -> post(
    { url => 'http://www.neopets.com/useobject.phtml',
      referer => 'http://www.neopets.com/useobject.phtml',
      no_cache => 1,
      params => {
        obj_id => $item -> id(),
        action => "Give+to+$friend",
      }
    } );

  return $page =~ /You have given/;
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
