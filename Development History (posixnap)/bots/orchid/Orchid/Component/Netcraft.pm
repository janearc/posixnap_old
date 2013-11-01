package Orchid::Component::Netcraft;

=head1 NAME

Orchid::Component::Netcraft

=cut

=head1 ABSTRACT

Orchid component for querying the netcraft.com site for statistics
about a particular host.

=cut

# ORIGINAL AUTHOR, ANDREAS SELTENREICH

use strict;
use warnings;

use POE qw{ Session Component::Client::HTTP };
use HTML::Entities;

# no need to be snotty, andreas.
sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew($thischan, $thisuser, ":netcraft <domain name|IPv4 address>".
		"- queries netcraft.com for the HTTP Server/OS running on the specified host");
}

POE::Component::Client::HTTP -> spawn (
	Alias => 'OrchidNetcraftHTTPClient',
	Timeout => '180',
);

POE::Session -> create (
	inline_states => {
		_start => {
			$_[KERNEL] -> alias_set( 'OrchidNetcraft' );
		},

		netcraftRequest => sub {
			my ($kernel) = $_[ KERNEL ];
			my ($host) = $_[ ARG0 ];
			if (goodHostName( $host )) {
			}
			else {
				# XXX: yield here an error
			}

sub do_netcraft {

	my ($thischan, $thisuser, $thismsg) = @_;
	
	my ($query) = $thismsg =~ /^:netcraft\s+(\S*)/;
	return unless defined $query;
	
	unless ( $query =~ /^(([a-z]([a-z0-9-]*[a-z0-9]+)?\.?)*|([0-9]+\.){3}[0-9]+)$/i ) {
		utility::spew( $thischan, $thisuser, "I'm sorry, $thisuser, " 
			."please read rfc883 to learn what intarweb addresses look like" );
		return UNSPECIFIED_ERROR;
	}
		
	# yay, we have an http agent, thanks alex.

	my ($agent) = Broker::HTTPReq -> new();
	my $url = "http://uptime.netcraft.com/up/graph/?mode_u=off&mode_w=on&site=$query";
	utility::debug( "netcraft.pm: surfing to: $url" );
	my ($content) = $agent -> httpreq_cached_get( $url );
	my (@results);
	
	if (defined $content) {
		if ( $content =~ m!The site <[^>]+.([^<]+)</a>[\s\n\r]*is running <b>([^<]+)</b> on <b>([^<]+)</b>!gm ) {
			utility::spew( $thischan, $thisuser, "netcraft.com says: $1 is running $2 on $3");
			return SUCCESS;
		} 
		elsif ( $content =~ /The host name you have selected is not valid/) {
			utility::spew( $thischan, $thisuser, "I'm sorry, $thisuser, I'm afraid netcraft couldn't contact this host" );
		} 
		else {
			utility::spew( $thischan, $thisuser, "I'm sorry, $thisuser, I'm afraid netcraft.com didn't do that." );
		}
	}
	else {
		utility::spew( $thischan, $thisuser,  "I'm sorry, $thisuser, I'm afraid I could not retrieve $url" );
		return INTARWEB_ERROR;
	}
}
