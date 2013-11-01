package Neopets::Shops;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Shops - Neopets shop tools

=head1 SYNOPSIS

=head1 ABSTRACT

This module holds several tools for manipulating
external neopet shops.  Tools for your internal
shop (your own shop) are found in Neopets::Shops::Mine.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

=item $shop = Neopets::Shops -> new;

This constructor takes a Neopets::Agent
object as a parameter and returns a
Neopets::Shops object

=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
  my ( $args ) = @_;

  my $agent = $args -> {agent};
  my $common = $args -> {common};
  my $wizard = $args -> {wizard};
  $DEBUG = $args -> {debug};

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }

  return bless {
    objects => {
      agent => $agent,
      common => $common,
      wizard => $wizard,
    },
  }, $this;
}

=item @items = @{ $shop => listing( $owner ) };

This method returns a name => location hash
containing the names and buy locations
of every object in $owner's shop.

=cut

sub listing {
  my $self = shift;
  my $owner = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> get(
    { url =>  "http://www.neopets.com/browseshop.phtml",
      no_cache => 1,
      params => { owner => $owner },
    } );

  my @items = $response =~ m!<a href='(buy_item.phtml[^']+)'.*?<b>([^<]+)</b>!g;

  my %listing = ( );
  while ( @items ) {
    map { $listing{ $_->[1] } = $_->[0] } [ shift @items, shift @items ];
  }

  return \%listing;
}

=item $shop -> buy( $item );

This method takes an $item object (see
Neopets::Item::Simple) and returns true
if the item was bought.  The $item object
must have a $location.  Optionally, the
$item can also have a $referer set (the
$owner field can substitute for a
referer).
note. if $referer and $owner are both
set, $referer has presidence.

=cut

sub buy {
  my $self = shift;
  my $item = shift;

  unless ( $item -> location() )
    { fatal( "the provided item must have a location" ) }

  my $agent = ${ $self -> {objects} -> {agent} };

  my $url = $item -> location();
  unless ( $url =~ /^http/ )
    { $url = "http://www.neopets.com/$url" }
    
  my $referer = $item -> referer() || $item -> owner();

  my $response;

  if ( $item -> negotiable() ) {
    unless ( $item -> referer() )
      { fatal( "this type of item requires a referer" ) }

    my $page = $agent -> get({ url => $url });

    my $grr = $page =~ /name='grr' value='(\d+)'/;
    my $price = $item -> price();
    my $offer = int( $price * .9 );

    debug( "attempting to buy for $offer" );

    $response = $agent -> post(
      { url => 'http://www.neopets.com/haggle.phtml',,
        referer => $item -> referer(),
        params => { current_offer => $offer, grr => $grr },
        no_cache => 1,
      } );
  } elsif ( $referer ) {
    unless ( $referer =~ /^http/ )
      { $referer = "http://www.neopets.com/browseshop.phtml?owner=$referer" }

    $response = $agent -> get( { url =>  $url, referer => $referer, no_cache => 1 } );
  } else {
    debug( "no referer specified in item object, trying anyhow..." );
    $response = $agent -> get( { url => $url, no_cache => 1 } );
  }
  
  if ( $response ) {
    unless ( ( $response =~ m/does not exist/ )
          or ( $response =~ m/Too late/ ) 
          or ( $response =~ m!have less than <b>10,000 NP</b>! )
          or ( $response =~ /you can only carry a maximum/ ) ) {
      return 1;
    }
  } else {
    debug ( "There was an error fetching : $url " );
  }

  return 0;
}

=item $shop -> buy_direct( $item );

This method is similar to buy(), but incorporates
the wizard.  It finds and buys the cheepest item,
price independant.

=cut

sub buy_direct {
  my $self = shift;
  my $item_name = shift;

  fatal( 'must supply item' )
    unless $item_name;

  require Neopets::Shops::Wizard;
  require Neopets::Item::Simple;
  require Neopets::Common;

  # make an item object if necessay
  my $item = $item_name;
  unless ( $item -> can('name') ) {
    $item = Neopets::Item::Simple -> new(
      { name => $item } )
        || fatal ('unable to create item object' )
 }

  my $agent = ${ $self -> {objects} -> {agent} };

  my $wizard; # set/create a wizard object
  if ( defined $self -> {objects} -> {wizard} ) {
    $wizard = ${ $self -> {objects} -> {wizard} };
  } else {
    $wizard = Neopets::Shops::Wizard -> new( $self -> {objects} )
        || fatal( 'unable to create wizard object' );
  }

  my $common; # set/create a common object
  if ( defined $self -> {objects} -> {common} ) {
    $common = ${ $self -> {objects} -> {common} };
  } else {
    $common = Neopets::Common -> new( $self -> {objects} )
        || fatal( 'unable to create common object' );
  }
  
  my $name = $common -> username();
  my @item_list = @{ $wizard -> search(
    { item => $item,
      exact => 1,
    } ) };

  # exit if not found
  if ( @item_list == 0 ) {
    return 0;
  } elsif ( $item_list[0] eq 'BUSY' ) {
    return 0;
  } elsif ( $item_list[0] eq 'NONE FOUND' ) {
    return 0;
  }

  # get shop from list (not your own)
  my $item_to_buy;
  if ( $item_list[0] -> owner() eq $name ) {
    $item_to_buy = $item_list[1];
  } else {
    $item_to_buy = $item_list[0];
  }

  # get shop listing
  my $shop_listing = $self -> listing( $item_to_buy -> owner() );
  # get item url from shop and set the item with it
  $item_to_buy -> location(
      $shop_listing -> { $item_to_buy -> name() } );

  # something is wrong if $url is undef
  die "item not found in shop, make sure make is correct (case)\n"
      unless ( $item_to_buy -> location() );

  # buy it
  debug( "buying a '".$item_to_buy->name()."' for ".$item_to_buy -> price() );
  if ( $self -> buy( $item_to_buy ) )
    { return 1 }
  else
    { return 0 }
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
