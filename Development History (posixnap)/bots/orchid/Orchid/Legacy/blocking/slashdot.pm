use warnings;
use strict;

use Broker::HTTPReq;
use Broker::NVStorage;

my $agent = Broker::HTTPReq -> new();
my $store = Broker::NVStorage -> new();

sub sd_retrieve {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my $content = $agent -> httpreq_cached_get('http://slashdot.org/slashdot.xml');
	my (@stories) = $content =~ m!<story>(.*?)</story>!sg;
	my $spew = ""; my ($date, $asof);
	# we only need the first five.
	foreach my $story (@stories[0 .. 4]) {
		my ($title) = $story =~ m!<title>([^<]+?)</title>!s;
		my ($url) = $story =~ m!<url>([^<]+?)</url>!s;
		($date) = $story =~ m!<time>([^<]+?)</time>!s;
		if (not $asof) { 
			$asof = $date;
		}
		$store -> nv_store( 
			$title, 
			{ 
				url => $url, 
				ts => time(), 
				date => $date,
				title => $title,
			} 
		);
		$spew .= "$title | ";
	}
	$spew = "Slashdot as of $asof - ".$spew;
	utility::spew( $thischan, $thisuser, $spew );
}

sub sd_info {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my @keys = @{ $store -> nv_records() };

	my ($query) = $thismsg =~ /^:sdinfo\s+(.*)/;
	return unless $query;
	my @candidates = grep { 
		/^[^']+'(.*)/;
		$1 =~ /$query/i
	} @keys;
	if (@candidates and $#candidates > 1) {
		utility::spew( $thischan, $thisuser, "try: ".
			@candidates ? ((shift @candidates) =~ /^[^']+'(.*)$/) ? $1 : return 1 : return 1
		) for ( 1 .. 4 );
		return 1;
	}
	elsif (@candidates == 1) {
		# timtowtdi, baybee
		my $data = ${ $store -> nv_retrieve( ((shift @candidates) =~ /^[^']+'(.*)$/) and $1 ) }; # there's only one key
		utility::spew( 
			$thischan, $thisuser, 
			"[ ".$data -> {date}." ] ".$data -> {title}." <".$data -> {url}.">"
		);
		return 1;
	}
	else {
		utility::spew( 
			$thischan, $thisuser, "sorry, $thisuser, no matching keys found." 
		);
		return 1;
	}
}

sub private {
	my ($thischan, $thisuser, $thismsg) = (@_);
	sd_retrieve( @_ ) if $thismsg eq ":slashdot";
	sd_info( @_ ) if $thismsg =~ /^:sdinfo \S+/;
}

sub public {
	my ($thischan, $thisuser, $thismsg) = (@_);
	sd_retrieve( @_ ) if $thismsg eq ":slashdot";
	sd_info( @_ ) if $thismsg =~ /^:sdinfo \S+/;
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
:slashdot to pull headlines off slashdot (limit 5)
:sdinfo [ string ] to pull a headline from the slashdot cache matching /string/ (you may have to issue :slashdot first)
HELP
}
