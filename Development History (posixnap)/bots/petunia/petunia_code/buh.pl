code
sub buh {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "buh" if @_ == 0;
	return 0 unless $thismsg =~ /^(!+)buh\s+(.*)/;
	my ($ems, $victim_s) = split /buh\s+/, $thismsg;
	my @victims = split /\s+/, $victim_s;
	$ems = length $ems;
	for (1 .. $ems) {
		$nap -> private_message($_, "buh!") for @victims;
	}
	return 1;
}

(1 row)
