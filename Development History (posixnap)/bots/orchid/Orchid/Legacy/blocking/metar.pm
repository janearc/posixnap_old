use warnings;
use strict;

use Broker::HTTPReq;
use Geo::METAR;
use Aviation::Report;

my $geo_m = new Geo::METAR;
my $agent = Broker::HTTPReq -> new();

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, 
		":metar XXXX [ literal ] returns METAR data (literally) for the requested station."
	);
	utility::spew( $thischan, $thisuser, 
		"returns [1] or [2] depending on which source was used. (utsl.)"
	);
}

sub public {
	parse( @_ );
}

sub private {
	parse( @_ );
}

sub parse {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless my ($station, $literal) = $thismsg =~ /^:metar\s+([a-z]{4})\s*(literal)?/i;
	uc $station;
	my $metar = metar_get( $station );
	utility::debug("got $metar");
	if (defined $metar) {
		if ($literal) {
			utility::private_notice( $thischan, $thisuser, $metar );
			return;
		}
		elsif (defined metar_dump( $metar )) {
			utility::private_notice( $thischan, $thisuser, metar_dump( $metar ) );
			return;
		}
		else {
			utility::spew( $thischan, $thisuser, "Error parsing '$metar'" );
			return;
		}
	}
	else {
		utility::spew( $thischan, $thisuser, "Error retreiving info for $station" );
		return;
	}
}

sub metar_get {
	my $CODE = shift;
	my $page = $agent -> httpreq_cached_get(
		'http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc='.
		$CODE
	);
	return undef if not $page;
	my ($metar) = $page =~ m!
		<tt><font\s* size=[+0-9]+>
		([^<]+)
		</font></tt>
	!xis;
	$metar =~ s/^\s*//;
	$metar =~ s/\s*//;
	return $metar or undef;
}

sub metar_dump {
	$geo_m -> debug(1);
	my $metar = shift;
	$geo_m -> metar( $metar );
	$geo_m -> debug(0);
	my $engrish = $geo_m -> dump(); # this might break, ick.
	if ($engrish !~ /\S/) {
		$engrish = decode_METAR_TAF( $metar ); # last ditch effort
		$engrish = "[2]: $engrish";
	}
	else {
		$engrish = "[1]: $engrish";
	}
	if ($engrish !~ /\S/) {
		return undef;
	}
	return $engrish;
}
