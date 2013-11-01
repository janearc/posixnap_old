package Neopets::Shops::Mine;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::Item::Simple;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Shops::Mine - Methods for working with your Neopets Shop

=head1 SYNOPSIS

  # create a shop object and use it

  use Neopets::Agent;
  use Neopets::Shops::Mine;

  my $agent = Neopets::Agent -> new();
  my $shop = Neopets::Shops::Mine -> new(
    { agent => \$agent } );

  my @inventory = @{ $shop -> inventory() };
  $shop -> quickstock( @inventory );

  $shop -> clear_sales_history();
  
  my $np = $shop -> get_till();
  $shop -> empty_till();

  my @history = @{ $shop -> history() };

=head1 ABSTRACT

This module provides functionality for working
with user's personal shop.  This includes the
personal item inventory as well as shop space.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant INVENTORY_URL => 'http://www.neopets.com/objects.phtml?type=inventory';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $object = Neopets::Template->new;

This constructor takes hash arguments and
returns a Shop object.  Optional arguments
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

=item $shop -> inventory();

This method returns the personal
item inventory belonging to the
user in an array of Neopets::Item::Simple
objects.

=cut

sub inventory {
  my $self = shift; # the Neopets::Shops::Mine object
  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get(
    { url => INVENTORY_URL,
      inventory => 'http://www.neopets.com/objects.phtml' } );

  my @openwins = split /onclick='/, $response;

  my @inventory = $response
    =~ m!border=1></a><br>([^<]+).*?onclick='openwin\((\d+)!g;
  
  my @items;
  while ( @inventory ) {
    my $item = Neopets::Item::Simple -> new(
      { name => shift @inventory,
        id => shift @inventory,
      } );
    push @items, $item;
  }

  return \@items;
}

=item $shop -> set_prices( @list );

This method takes a list of items and
if matching items (name wise) exist in
the shop, the price will be set to the
corresponding price field.

=cut

sub set_prices {
  my $self = shift;
  my @list = @_;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get( { url => 'http://www.neopets.com/market.phtml?type=your' } );
  my $url = 'http://www.neopets.com/process_market.phtml?type=update_prices';

  # XXX: needs a shop_inventory();
  my ( $form ) = $response =~ m!(<form action='process_market\.phtml'.*?/form>)!gs;
  my @items = $form =~ m!bgcolor='\#ffffcc'><b>([^<]+)</b>.*?<b>([^<]+)</b>.*?name='obj_id_([^']+)'.*?value='([^']+)'.*?value='([^']+)'.*?</tr>!g;

  return
    unless ( @items );

  my %stock = ( );
  while ( @items ) {
    map { $url = "$url&obj_id_".$_->[2]."=".$_->[3]."&oldcost_".$_->[2]."=".$_->[4];
          $stock{ $_->[2] } =
            { name => $_->[0],
              count => $_->[1],
              id => $_->[2],
              obj_id => $_->[3],
              old_cost => $_->[4],
            }
        } [ shift @items, shift @items, shift @items, shift @items, shift @items ];
  }

  foreach my $id ( sort {$a <=> $b} keys %stock ) {
    my $name = $stock{ $id } -> {name};
    my $old_cost = $stock{ $id } -> {old_cost};
    my $price;
    foreach my $item ( @list ) {
      if ( $stock{ $id } -> {name} eq $item -> name() ) {
        $price = $item -> price() }
    }
    if ( $price ) {
      $url =~ s/(oldcost_$id=\d+)/$1&cost_$id=$price/;
    } else {
      $url =~ s/(oldcost_$id=\d+)/$1&cost_$id=$old_cost/;
    }
  }

  $agent -> get( { url => $url, referer => 'http://www.neopets.com/market.phtml?type=your' } );
}

=item $shop -> stock_all();

This method moves the entire inventory
into the shop.

=cut

sub stock_all {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };
  my ( $url, $inventory ) = $self -> get_quickstock_list();

  foreach my $id ( keys %{$inventory} ) {
    $url .= "&radio_$id=stock"
  }

  my $response = $agent -> get(
    { url => $url,
      referer => 'http://www.neopets.com/quickstock.phtml',
      no_cache => 1,
    } );

  if ( $response =~ /you do not have enough room/ ) {
    return "Some or all of the items you added to your shop were not added because you do not have enough room!!!";
  }

  return 0;
}

=item $shop -> quickstock( @list );

This method takes an array of
Neopets::Item::Simple objects to
stock in the shop.  Only name fields
are used in these items.

NOTE: this is not currently true,
      takes a list of item names atm.

=cut

sub quickstock {
  my $self = shift;
  my @stock_items = @{ shift() };

  my $agent = ${ $self -> {objects} -> {agent} };

  my ( $url, $inventory ) = $self -> get_quickstock_list();

  foreach my $item ( @stock_items ) {
    chomp $item;
    debug( "Attempting to stock '$item'" );
    foreach my $id ( keys %{$inventory} ) {
      if ( $inventory -> {$id} eq $item )
        { $url = "$url&radio_".$id."=stock" }
    }
  }

  my $response = $agent -> get( 
    { url => $url,
      referer => 'http://www.neopets.com/quickstock.phtml',
      no_cache => 1,
    } );

  if ( $response =~ /you do not have enough room/ ) {
    return "Some or all of the items you added to your shop were not added because you do not have enough room!!!";
  }

  return 0;
}

=item $shop -> get_quickstock_list();

This method gets a piece of the url and
an item id hash used by the quickstock()
function.  There is never a reason to
use this directly.

=cut

sub get_quickstock_list {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get(
    { url => 'http://www.neopets.com/quickstock.phtml',
      no_cache => 1,
    } );

  my @itemlist = $response =~ m/<input type='hidden' name='name_([^']+)' value='([^']+)'>/g;
  my @idlist = $response =~ m/<input type='hidden' name='id_([^']+)' value='([^']+)'>/g;
  my %items = ( );

  my $url = "http://www.neopets.com/process_quickstock.phtml?buyitem=0";

  while ( @itemlist ) {
    map {
      $url = "$url&id_".$_->[0]."=".$_->[1];
    } [ shift @idlist, shift @idlist ];

    map {
      (my $i=$_->[1]) =~ y/ /+d/;
      $items{ $_->[0] } = $_->[1];
      $url = "$url&name_".$_->[0]."=$i";
    } [ shift @itemlist, shift @itemlist ];
  }

  return ( $url, \%items );
}

=item $shop -> get_till();

This method returns the ammount
of neopoints currently in the
shop till.

=cut

sub get_till {
  my $self = shift;
  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get(
    { url => 'http://www.neopets.com/market.phtml?type=till',
      referer => 'http://www.neopets.com/market.phtml?type=your'
    } );
  my ( $np ) = $response =~ m/You currently have <b>([^<]+)/;

  $np =~ y/, NP//d;

  return $np;
}

=item $shop -> empty_till();

This method empties the shop till.

=cut

sub empty_till {
  my $self = shift;
  my $agent = ${ $self -> {objects} -> {agent} };

  my $np = $self -> get_till();

  my $response =
    $agent -> get(
      { url => "http://www.neopets.com/process_market.phtml?type=withdraw&amount=$np",
        referer => "http://www.neopets.com/market.phtml?type=till" } );
}

=item $shop -> history();

This method returns a ref to an
array holding Neopets::Item::Simple
objects representing the shop
history.

=cut

sub history {
  my $self = shift;
  my $agent = ${ $self -> {objects} -> {agent} };

  my $response =
      $agent -> get( { url => 'http://www.neopets.com/market.phtml?type=sales' } );

  my ( $html ) = grep { /clear your Sales History/ } split '\n', $response;
  my @sales = $html =~ m!<tr>.*?align=center>(\d+/\d+/\d+)</td>.*?align=center>([^<]+)</td>.*?<b>([^<]+).*?align=center>([^<]+)</td></tr>!g;

  my @sale_list;
  while ( @sales ) {
    my $item = Neopets::Item::Simple -> new (
      { date => shift @sales,
        name => shift @sales,
	buyer => shift @sales,
	price => shift @sales,
      } );
    push @sale_list, $item;
  }

  return \@sale_list;
}

=item $shop -> clear_sales_history();

This method clears the neopets shop
sales history.

=cut

sub clear_sales_history {
  my $self = shift;
  my $agent = ${ $self -> {objects} -> {agent} };

  $agent -> get( { url => "http://www.neopets.com/market.phtml?type=sales&clearhistory=true",
                   referer => "http://www.neopets.com/market.phtml?type=sales" } );
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
