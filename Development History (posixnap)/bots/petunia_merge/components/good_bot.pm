
# this is necessary for retort
sub good_bot {
    my ($thischan, $thisuser, $thismsg) = (@_);
    #return "good_bot" if @_ == 0;
    my $nick = $utility::config{nick};
    return 0 unless $thismsg =~ /($nick,? goo+d bot|goo+d bot,? $nick|thanks? $nick)/i;
    if ($1 =~ /thanks/i) { 
	utility::spew($thischan, $thisuser, "yer welcome $thisuser");
	return 1;
    }
    else {
	utility::spew($thischan, $thisuser, "thanks $thisuser");
  	return 1;
    }
    return 0;
}


sub public {
    good_bot( @_ );
}


sub private {
    good_bot( @_ );
}


sub emote {
}

1;
