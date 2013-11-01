# blatantly copied from infobot.

use strict;
use warnings;
use Net::Telnet;
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
	return unless (my ($insultee) = $thismsg =~ /^:insult (.*)/);
	my $t = new Net::Telnet ( Errmode => "return", Timeout => 3 );
	$t -> Net::Telnet::open( Host => "insulthost.colorado.edu", Port => "1695" );
	my $line = $t -> Net::Telnet::getline( Timeout => 4 );
	chomp $line;
	$line =~ s/you are nothing but a/is a/i;
	if ($line) {
		utility::spew( $thischan, $thisuser, ucfirst $insultee." ".lc $line );
		undef $tries;
	}
	else {
		if ($tries >= 4) {
			utility::spew( $thischan, $thisuser, "$insultee was saved by a lame server at insulthost.colorado.edu" );
			return 0;
		}
		insult( @_ );
		$tries++;
	}
}
