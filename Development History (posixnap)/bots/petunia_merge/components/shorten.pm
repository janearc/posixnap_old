# requested by sammy

use warnings;
use strict;

use LWP::Simple qw{ $ua get };
use URI::Escape qw{ uri_escape };

# optionally set the user agent
$ua->agent(qq{ Petunia [ http://minotaur.posixnap.net/cgi-bin/cvsweb.cgi/bots/petunia_merge/ ] });

sub shorten {
	my $long_url = uri_escape(shift());
	
	# use $ua from LWP::Simple to do a post
	# XXX: i expect this will fail if it ever gets anything other than success.
	my $short_url = $ua -> post(
		"http://metamark.net/api/rest/simple", { 
			long_url => $long_url 
		}
	) -> content();
	
	return $short_url;
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "this function is not interactive." );
}

sub public {
	parse( @_ );
}

sub private {
	parse( @_ );
}

sub parse {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my $shorter;

	if (my ($url_to_shorten) = $thismsg =~ m!(http://\S+)!) {
		$shorter = shorten( $url_to_shorten ) if length $url_to_shorten > 21;
	}
	else {
		return undef;
	}
	return undef unless $shorter;
	utility::spew( $thischan, $thisuser, "shortened: $shorter" );
	return;
}

