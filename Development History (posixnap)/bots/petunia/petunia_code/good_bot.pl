code
# this is necessary for retort
sub good_bot {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "good_bot" if @_ == 0;
  return 0 unless $thismsg =~ /(?:$mynick,? good bot|good bot,? $mynick|thanks? $mynick)/i;
	if ($1 =~ /thanks/i) { 
		$nap -> public_message("yer welcome $thisuser");
		return 1;
	}
	else {
  	$nap -> public_message("thanks $thisuser");
  	return 1;
	}
	return 0;
}

(1 row)
