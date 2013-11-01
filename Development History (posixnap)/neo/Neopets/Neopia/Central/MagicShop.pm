package Neopets::Neopia::Central::MagicShop;

#
# MagicShop.pm
#
# Simple class for abstracting Kauvara's Magic Shop in
# Neopia central. Quite often, expensive items show up here
# for roughly 1/4 to 1/3 the going price on the wizard or
# the trading post. This can mean profits from 2,000 or so
# for a faerie to 80,000 for a fire lupe morphing potion.
#

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::Item::Simple;

# debug flag
our $DEBUG = 0;

use constant KAUVARA_URL => 'http://www.neopets.com/objects.phtml?type=shop&obj_type=2';

# this is matt's constructor.
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

sub inventory {
	my $self = shift;
	my $agent = ${ $self -> {objects} -> {agent} };
	
	my $shop_page = $agent -> get({
		url => KAUVARA_URL,
		referer => KAUVARA_URL, # we'll pretend we just hit refresh
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
	while (my ($location, $itemname, $instock, $cost) = $shop_page =~ m!
		<a href='(haggle.phtml\?obj_info_id=\d+&stock_id=\d+&g=\d+)'
		\s+onClick.*?
		border=1></a><br><b>([^<]+)</b>
		<br>(\d+)\s+in\s+stock
		<br>Cost\s+:\s+([0-9,]+)\s+NP<br
	!sgoix) {
		# loop me round and round
		# dare I create a Neopets::Item::Cart module?
		my $item = Neopets::Item::Simple -> new();
		$item -> name( $itemname );
		$item -> location( $location);
		$item -> cost( $cost );
		$item -> referer( KAUVARA_URL );
		$item -> quantity( $instock );
		push @cart, $item;
	}
	return \@cart; # this is still anonymous because it descopes, and this is a
	# performance gain over [ @cart ].
}

1;
