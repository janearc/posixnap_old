package Neopets::Shops::Wizard;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::Item::Simple;
use Neopets::HTML::Form;
use Neopets::HTML::Table;
use Data::Dumper;

# debug flag
our $DEBUG = 0;

=head1 NAME

Neopets::Shops::Wizard - A wizard search interface

=head1 SYNOPSIS

  # creating a wizard object and using it

  use Neopets::Agent;
  use Neopets::Shops::Wizard;

  my $agent = Neopets::Agent -> new();
  my $wizard = Neopets::Shops::Wizard -> new(
    { agent => \$agent } );

  my $item_list = $wizard -> search(
      { item => $name, exact => $exact,
        min_price => $min, max_price => $max } );

=head1 ABSTRACT

This module is an interface to the Neopets Shop
Wizard.  It has methods for searching and
retrieving shop based information from the wizard.

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

=item my $wizard = Neopets::Shops::Wizard -> new;

This constructor takes hash arguments and
returns a wizard object.  Optional arguments
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

=item $wizard -> search();

This method takes hash style
parameters and returns an array of
Item objects (see Neopets::Item::Simple).

The arguments this function takes are:
  item => (Neopets::Item::Simple, item to find)
  exact => (if the wizard is to search
            for the exact name)
  min_price => (minimum price)
  max_price => (maximum price)

=cut

sub search {
  my $self = shift;

  # get the arg hash
  my ( $args ) = @_;

  # get a form from the site
  my $agent = ${ $self -> {objects} -> {agent} };
  # get params and action
  my ( $params, $action );
  {
    # none of this needs to stay on scope
    my $page = 
      $agent -> get(
        { url => $Neopets::URL::MARKET,
          referer => $Neopets::URL::MARKET,
          params => { type => 'wizard' }, } );
    my $form = get_forms( { page => => $page } );
    $action = ${ $form }[1] -> {action};
    $params = parse_form( { form => ${ $form }[1] } );
  }

  # make sure i am given the right info
  fatal( 'item parameter must be of type Neopets::Object::Simple' )
    unless ( $args -> {item} and $args -> {item} -> can('name') );

  # get the actual values out of the hash
  $params -> {shopwizard} = $args -> {item} -> name();
  $params -> {max_price} = $args -> {max_price};
  $params -> {min_price} = $args -> {min_price};

  # fix $item for use in url
  $params -> {shopwizard} =~ y/ /+/d;

  # 'exact' or 'containing'
  if ( $args -> {exact} ) { $params -> {criteria} = 'exact' }
    else { $params -> {criteria} = 'containing' }

  # XXX: added these
  $params -> {type} = 'process_wizard';
  delete $params -> {lang};

  #print Dumper $params,
  #  "http://www.neopets.com/$action",
  #  "http://www.neopets.com/$action";

  # XXX changed this to a POST, altered url and referer

  # fetch
  my $response =
    $agent -> post(
        { url => "http://www.neopets.com/market.phtml",
          referer => "http://www.neopets.com$action",
          params => $params,
          no_cache => 1,
        } );

  # return error case and delay time if wizard is busy
  if ( $response =~ 'busy right now' ) {
    my ( $time ) = $response =~ m/<b>(\d+)<\/b> minutes/;
    return [ 'BUSY', $time ];
  } elsif ( ( $response =~ /I did not find anything/ ) 
         or ( $response =~ /they were priced at 0 Neopoints/ ) ) {
    return [ 'NONE FOUND' ];
  }

  ( $response ) = grep { /Searching/ } split '\n', $response;

  # catch an error
  unless ( $response ) {
    debug( "something went wrong, could not find an item list, are you sure you are logged in?" );
    print "$response\n";
    return;
  }

  # get the juicy stuff
  my $table = parse_table_quick(
    { page => $response, strip => 1 } );

  # the first line is the table header
  # remove it
  shift @{ $table };

  my @item_list = map {
    my @keys = keys %{ $_ };
    my $owner = $keys[0];
    my $name = $_ -> {$owner} -> [0];
    my $quantity = $_ -> {$owner} -> [1];
    my $price = $_ -> {$owner} -> [2];
    $price =~ y/, NP//d;

    my $item = new Neopets::Item::Simple(
        { owner => $owner,
          name => $name,
          quantity => $quantity,
          price => $price,
        } );
    $item;
    } @{ $table };

  #my @list =
  #    $response =~ m!owner=([^']+).*?bgcolor='\#ffffcc'>([^<]+).*?bgcolor='\#ffffcc'>(\d+).*?<b>([^<]+)!g;

  #unless ( @list ) {
  #  debug( "something went wrong, could not find an item list" );
  #  return;
  #}

  # use the contents of @list to generate
  # items and put them into a list
  #my @item_list;
  #while ( @list ) {
  #  my $item = Neopets::Item::Simple -> new();
  #  $item -> owner( shift @list );
  #  $item -> name( shift @list );
  #  $item -> quantity( shift @list );
  #  my $price = shift @list;
  #  $price =~ y/, NP//d;
  #  $item -> price( $price );
  #  push @item_list, $item;
  #}

  return \@item_list;
}

=item $wizard -> statistics();

This method takes an item name
as an argument and returns a
Statistics::Descriptive object
representing the prices found
for the item. The item name is
assumed to be exact. This method
searches for data three times
and returns the cumulative results.

=cut

sub statistics {
  my $self = shift;
  my $item = shift;

  eval { require Statistics::Descriptive::Full }
    or fatal( "requires Statistics::Descriptive::Full to be installed" );

  my $stat = new Statistics::Descriptive::Full -> new();

  foreach ( 1 .. 3 ) {
    my @prices =
        map { $_ -> price() }
            @{ $self -> search( { item => $item, exact => 1 } ) };

    $stat -> add_data( @prices );
  }

  $stat -> sort_data();

  return $stat;
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
