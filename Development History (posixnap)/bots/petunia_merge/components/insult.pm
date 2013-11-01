# blatantly copied from infobot.

use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
our $tries;

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, 
		":insult <insultee> - queries insulthost.colorado.edu and insults the insultee"
	);
}

sub public {
	do_insult( @_ );
}

sub private {
	do_insult( @_ );
}

sub do_insult {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless (my ($insultee) = $thismsg =~ /^[!|:]insult (.*)/);
	my @content = split( /\n/, get("http://www.upstartx.com/abuse/abuse.cfm"));
	chomp @content;
	$content[54] =~ s/\"//g;
	$content[54] =~ s/\s+/ /g;
	#$line =~ s/you are nothing but a/is a/i; # this is such a lame hack.
	utility::spew( $thischan, $thisuser, ucfirst $insultee.", ".lc $content[54]);
}
