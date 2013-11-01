##
## googlism.pm
##
## as of now, it appears that the radio buttons (Who, What, Where, When) 
## warrant no difference in results - hence, this module currently
## does _not_ accommodate any options aside from 'Who.' In the event
## that this is no longer the case, _please_ contact the author:
## Cormac Mannion <cormac@posixnap.net>
##

use constant UNSPECIFIED_ERROR => 5;
use constant INTARWEB_ERROR => 6;

use constant SUCCESS => 255;

use strict;
use warnings;
use Broker::HTTPReq;
use HTML::Entities;

sub do_googlism {

	my ($thischan, $thisuser, $thismsg) = @_;
	
	my ($query) = $thismsg =~ /^:googlism\s+(.*)/;
	return unless $query;
	my $html_query = $query;
	$html_query =~ y/ /+/;
	
	if (not length ($query)) {
		# invalid query kthx
		utility::debug( "no query issued" );
		return UNSPECIFIED_ERROR;
	}
	
	# yay, we have an http agent, thanks alex.

	my ($agent) = Broker::HTTPReq -> new();
	my $url = "http://googlism.com/index.htm?ism=$html_query";
	my ($content) = $agent -> httpreq_cached_get( $url );
	my (@results);
	
	if (defined $content) {
		if ( (@results) = $content =~ m!($query is [^<]+)<br>!sg ) {
			my $result = $results[ rand @results ];
			# this gets rid of &nbsp;, &lt;, and so on.
			$result = decode_entities( $result );
			utility::spew( $thischan, $thisuser, $results[ rand @results ] );
			return SUCCESS;
		}
		else {
			utility::spew( $thischan, $thisuser, "google doesn't know enough about $query." );
		}
	}
	else {
		utility::debug( "ack! could not retrieve $url" );
		return INTARWEB_ERROR;
	}
}

sub help {
	my ($thischan, $thisuser, $thismsg) = ( @_ );
	utility::spew( $thischan, $thisuser, "syntax: ':googlism query'" );
}

sub public {
	do_googlism( @_ );
}

sub private {
	do_googlism( @_ );
}
