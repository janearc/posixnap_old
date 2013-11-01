use warnings;
use strict;

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "!buh [ username ] - guaranteed to annoy people." );
}

sub do_buh {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return 0 unless $thismsg =~ /^(!+)buh\s+(.*)/;
	# exclamation marks
	my ($ems, $victim_s) = split /buh\s+/, $thismsg;
	my @victims = split /\s+/, $victim_s;
	$ems = length $ems;
	my $buhs;
	for (1 .. $ems) {
		utility::private_spew($thischan, $_, "buh!") for @victims;
		$buhs++;
		return 1 if $buhs >= 5;
	}
	return 1;
}

sub private {
	do_buh( @_ )
}

sub public {
	do_buh( @_ )
}

sub emote {
	()
}

1;
