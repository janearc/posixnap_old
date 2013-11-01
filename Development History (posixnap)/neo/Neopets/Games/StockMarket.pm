package Neopets::Games::StockMarket;

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Games::StockMarket - A stock market module

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

=item $market = Neopets::Games::StockMarket->new;

This constructor takes hash arguments and
returns a market object.  Optional arguments
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

=item $portfolio = $market -> portfolio();

This method returns a hashref representing
the user's stock portfolio.  $portfiolio
should look something like this:

  'BOOM' => {
    'open' => '19',
    'current' => '16',
    'value' => '80',
    'paid' => '16',
    'quantity' => '5',
    'change' => '+0.00%'
  }

=cut

sub portfolio {
  my $self = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $page = $agent -> get(
    { url => 'http://www.neopets.com/stockmarket.phtml?type=portfolio',
      no_cache => 1,
    } );

  my @stock_info = $page =~ m/ticker=([^']+).*?bgcolor='#eeeeff'>(\d+).*?<i>(\d+).*?<b>(-?\d+).*?bgcolor='#eeeeff'>(\d+).*?bgcolor='#eeeeff'>(\d+).*?<b>(\d+) NP.*?<b>([-+]\d+\.\d+%)/g;

  my $portfolio = { };
  while ( @stock_info ) {
    my $name = shift @stock_info;
    $portfolio -> {$name} = 
      { 'open' => shift(@stock_info),
        current => shift(@stock_info),
        change => shift(@stock_info),
        quantity => shift(@stock_info),
        paid => shift(@stock_info),
        value => shift(@stock_info),
        change => shift(@stock_info),
      };
  }

  return $portfolio;
}

=item $market -> buy( $stock, $count);

This method buys $count number of
$stock if possible.  Returns true if
successful.

=cut

sub buy {
  my $self = shift;
  my $stock = shift;
  my $count = shift;

  die "Insufficient information given, requires $stock and $count\n"
    unless $stock && $count;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $page = $agent -> get(
    { url => 'http://www.neopets.com/process_stockmarket.phtml',
      referer => 'http://www.neopets.com/stockmarket.phtml?type=buy',
      no_cache => 1,
      params => { type => 'buy', ticker_symbol => $stock, amount_shares => $count }
    } );
  
  return $page =~ /Your Portfolio/;
}

=item $market -> sell( $stock, $count );

Attempts to sell $count number of $stock
and returns success.

=cut

sub sell {
  my $self = shift;
  my $stock = shift;
  my $count = shift;

  die "Insufficient information given, requires $stock and $count\n"
    unless $stock && $count;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $page = $agent -> get(
    { url => 'http://www.neopets.com/stockmarket.phtml?type=sell',
      no_cache => 1,
    } );

  my @stock_list = $page =~ m/ticker=([^']+).*?bgcolor='#eeeeff'>(\d+).*?name='sell_(\d+)'.*?name='company_id_\3' value='(\d+)'/g;

  my $stocks = { };
  while ( @stock_list ) {
    my $name = shift @stock_list;
    my $quantity = shift @stock_list;
    my $number = shift @stock_list;
    my $stock_id = shift @stock_list;
    $stocks -> {$number} =
      { name => $name,
        quantity => $quantity,
        stock_id => $stock_id,
      }
  }

  my $stock_qty = { };
  my $sum = 0;
  foreach my $id ( keys %{ $stocks } ) {
    if ( ($count > 0 ) and (uc $stock eq $stocks -> {$id} -> {name}) ) {
      $stock_qty -> {$id} = 
        $stocks -> {$id} -> {quantity} > $count ?
          $count :
          $stocks -> {$id} -> {quantity};
      $count -= $stocks -> {$id} -> {quantity};
      $sum += $stocks -> {$id} -> {quantity};
    } else {
      $stock_qty -> {$id} = 0;
    }
  }

  # is there enough?
  if ( $count > 0 )
    { return }

  my $url = 'http://www.neopets.com/process_stockmarket.phtml?type=sell';
  my $params = { type => 'sell' };
  foreach my $id ( keys %{ $stock_qty } ) {
    $params -> { "sell_$id" } = $stock_qty -> {$id};
    $params -> { "comany_id_$id" } = $stocks -> {$id} -> {stock_id};
    $params -> { "ammount_shares_$id" } = $stocks -> {$id} -> {quantity};
    $url = "$url&sell_$id=".$stock_qty -> {$id}."&comany_id_$id=".$stocks -> {$id} -> {stock_id}."&ammount_shares_$id=".$stocks -> {$id} -> {quantity};
  }

  $page = $agent -> get(
    { url => $url,
      referer => 'http://www.neopets.com/stockmarket.phtml?type=sell',
      no_cache => 1,
    } );

  print "$page\n";

  return $stocks;
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
