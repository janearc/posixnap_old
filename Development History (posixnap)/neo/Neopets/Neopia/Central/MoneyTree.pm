package Neopets::Neopia::Central::MoneyTree;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::Item::Simple;

# debug flag
our $DEBUG = 0;

=head1 NAME
Neopets::Neopia::Central::MoneyTree - MoneyTree module

=head1 SYNOPSIS

  # create a MoneyTree object and use it to get free
  # stuff

  use Neopets::Agent;
  use Neopets::Neopia::Central::MoneyTree;

  my $agent = Neopets::Agent -> new();
  my $tree = Neopets::Neopia::Central::MoneyTree -> new(\$agent);

  my @items = @{ $tree -> get_list() };

=head1 ABSTRACT

This module interfaces the Neopets MoneyTree
(see Neopets::Agent).

This module requires that a variable NP_HOME be set in order to function.
This should be the path to a writable directory in which this toolkit
can store information.

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

use constant TREE_URL => 'http://www.neopets.com/donations.phtml';

=item $tree = Neopets::Neopia::Central::MoneyTree->new;

This constructor takes hash arguments and
returns a tree object.  Optional arguments
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

=item my $item_array_ref = $tree -> get_list();

This method gets a list of all items at the
Money Tree.

=cut

# XXX: this should set a name as well
sub get_list {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get( { url => TREE_URL } );

  my ( $html ) =
      grep { /takedonation_new.phtml/ }
          split "\n", $response;
  my @list = $html =~
      m!<a href='([^']+?)'>.*?<b>([^<]+)</b>!g;

  my @items;
  while ( @list ) {
    my $item = Neopets::Item::Simple -> new();
    $item -> location( shift @list );
    $item -> name( shift @list );
    $item -> referrer( 'http://www.neopets.com/donations.phtml' );
    push @items, $item;
  }

  return \@items;
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

