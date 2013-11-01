# This is a blatant rip-off of googlism.pm
use constant UNSPECIFIED_ERROR => 5;
use constant INTARWEB_ERROR => 6;

use constant SUCCESS => 255;

use strict;
use warnings;
use Broker::HTTPReq;
use HTML::Entities;

sub do_ebay {

	my ($thischan, $thisuser, $thismsg) = @_;
	
	my ($query) = $thismsg =~ /^:ebay\s+(.*)/;
	return unless $query;
	my $html_query = $query;
	$html_query =~ y/ /+/;
	
	if (not length ($query)) {
		# invalid query kthx
		utility::debug( "no query issued" );
		return UNSPECIFIED_ERROR;
	}
       
	my ($agent) = Broker::HTTPReq -> new();
        my $url = "http://search.ebay.com/search/search.dll?cgiurl=http%3A%2F%2Fcgi.ebay.com%2Fws%2F&krd=1&from=R8&MfcISAPICommand=GetResult&ht=1&SortProperty=MetaEndSort&query=$html_query&js=0";
	my ($content) = $agent -> httpreq_cached_get( $url );
	my (@results);
	
	if (defined $content) {
		if ( (@results) = $content =~ m!</td><td.*><font size.*><a href.*\">(.*)</a></font>! ) {
		    my $result = $results[ rand @results ];
		    # this gets rid of &nbsp;, &lt;, and so on.
		    $result = decode_entities( $result );
		    utility::spew( $thischan, $thisuser, "$results[ rand @results ] -> $url" );
		    return SUCCESS;
		}
		else {
			utility::spew( $thischan, $thisuser, "couldn't find $query on ebay." );
		}
	}
	else {
		utility::debug( "ack! could not retrieve $url" );
		return INTARWEB_ERROR;
	}
}

sub help {
	my ($thischan, $thisuser, $thismsg) = ( @_ );
	utility::spew( $thischan, $thisuser, "syntax: ':ebay query'" );
}

sub public {
	do_ebay( @_ );
}
