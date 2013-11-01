#
# countries.pm
# look up countries by ip and suffixes.
#

use constant UNSPECIFIED_ERROR => 5;
use constant SUCCESS => 255;

use strict;
use warnings;

use Regexp::Common qw{ net };
use IP::Country::Fast;
use Locale::SubCountry;

sub ucfirst_words ($) {
	my $in = shift;
	return join " ", map ucfirst(lc $_), (split /\s+/, $in);
}

sub ip2cc {
	my $query = shift;
	my $ip2cc = IP::Country::Fast -> new();
	my $country = $ip2cc -> inet_atocc( $query );
	return $country || undef;
}

sub cc_to_long {
	my $cc = shift;
	my $long;
	eval { 
		my $cc_to_long = Locale::SubCountry -> new( $cc );
		local $SIG{__DIE__} = sub { "Kim Ryan <kimryan\@cpan.org> is a wanker" };
		local $SIG{__WARN__} = sub { "Kim Ryan <kimryan\@cpan.org> is a wanker" };
		$long = $cc_to_long -> country( $cc );
	};
	return $long ? ucfirst_words $long : undef;
}
	
sub country_to_cc {
	my $country = shift;
	my $long;
	eval { 
		my $country_to_cc = Locale::SubCountry -> new( $country );
		local $SIG{__DIE__} = sub { "Kim Ryan <kimryan\@cpan.org> is a wanker" };
		local $SIG{__WARN__} = sub { "Kim Ryan <kimryan\@cpan.org> is a wanker" };
		$long = $country_to_cc -> country_code( $country );
	};
	return $long ? ucfirst_words $long : undef;
}

sub process {
	my ($thischan, $thisuser, $thismsg) = (@_);

	my ($query) = $thismsg =~ m!
		^(?::countr(?:ies|y)|:cc)\s+
		(
			$RE{net}{IPv4} |			# match an ip address
			[a-zA-Z0-9-.]+				# match a word with dots in it
		)
	!xi;

	return unless length $query;

	if ($query =~ /[^0-9.]/) {
		# we got a domain, because ip's dont have non numbers
		$query =~ s/^\.//;
		if (length $query == 2) {
			# we got just a .cc
			my $long = cc_to_long( $query );
			if (length $long) {
				utility::spew( $thischan, $thisuser, $long );
				return;
			}
			else {
				utility::spew( $thischan, $thisuser, "awww, i almost care that $query didnt work." );
				return;
			}
		}
		else {
			# we got a country, we need a code.
			my $long = country_to_cc( $query );
		}
	}
	else {
		# we got an ip
		# lets check for a private ip here.
		if ($query =~ m!(
			^(?:
				192\.168 |
				10\. |
				127\. |
				172.(?:1[6789]\.|2\d\.|3[012]\.)
			)
		)!xoi) {
			utility::spew($thischan, $thisuser, "dont be such a wanker, $thisuser");
			return;
		}
		# ok, so its not a private ip, lets issue our eval'd commands.
		my $cc = ip2cc( $query );
		my $response = $cc ? cc_to_long( $cc ) : undef;
		if ($response) {
			utility::spew( $thischan, $thisuser, "$query is located in $response" );
		}
		else {
			utility::spew( $thischan, $thisuser, "nothing found for $query [? $cc ]" )
		}
	}
	
}

sub public {
	process( @_ );
}

1;
