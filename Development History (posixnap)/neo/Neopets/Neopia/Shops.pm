package Neopets::Neopia::Shops;

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Debug;
use Neopets::Item::Simple;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Neopia::Shops - A Neopian shop module

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

our $SHOPS = {
    # Neopia Central
  BookShop => 'http://www.neopets.com/objects.phtml?type=shop&obj_type=7',
  FoodShop => 'http://www.neopets.com/objects.phtml?type=shop&obj_type=1',
  MagicShop => 'http://www.neopets.com/objects.phtml?type=shop&obj_type=2',
};

=item $shop = Neopets::Neopia::Shops -> new;

This constructor takes hash arguments and
returns a shop object.  This requires atleast
one hashref argument:
  shop => $shop_name ( name of shop to be used )
This can be found in the keys of the hashref:
  $Neopets::Neopia::Shops::SHOPS

Optional arguments are:
  agent => \$agent (takes a Neopets::Agent ref)
  debug => $debug  (true or false)

=cut

sub new {
  my $that = shift;
  my $this = ref( $that ) || $that;
  my ( $args ) = @_;

  my $agent = $args -> {agent};
  my $shop = $args -> {shop};
  $DEBUG = $args -> {debug};

  if (! $shop ) {
    debug( "requires a shop name" );
  } elsif (! $SHOPS -> {$shop} ) {
    fatal( "provided shopname '$shop' is invalid" );
  }

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }

  return bless {
    objects => {
      agent => $agent,
      shop_url => $shop ? $SHOPS -> {$shop} : undef,
    },
  }, $this;
}

sub inventory {
	my $self = shift;
	my $agent = ${ $self -> {objects} -> {agent} };
    my $shop_url = $self -> {objects} -> {shop_url}
        or fatal( "no shop name was given in creation of this module" );
	
	my $shop_page = $agent -> get({
		url => $shop_url,
		referer => $shop_url, # we'll pretend we just hit refresh
	});

	my @cart;
	if ($shop_page =~ /Sorry, we are sold out/i) {
		# normally we would return undef. except if somebody says:
		# foreach my $foo (@{ $kauvara -> inventory() }) {
		# we get a fatal error with strict. do instead, we return a reference
		# to an empty list so we still return nothing, and we can test for it,
		# and we can iterate over it. sort of.
		return [ ];
	}

    my @item_info = $shop_page =~ m!<a href='(haggle.phtml\?obj_info_id=\d+&stock_id=\d+&g=\d+)'.*?<b>([^<]+)</b>.*?<br>(\d+).*?:\s+([0-9,]+)!g;
    
    while ( @item_info ) {
		my $item = Neopets::Item::Simple -> new();
        $item -> location( shift @item_info );
		$item -> name( shift @item_info );
        $item -> negotiable( 1 );
		$item -> quantity( shift @item_info );
		$item -> price( shift @item_info );
		$item -> referer( $shop_url );
		push @cart, $item;
	}
	return \@cart; # this is still anonymous because it descopes, and this is a
	# performance gain over [ @cart ].
}

1;
