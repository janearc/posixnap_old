sub do_date {
	my ($thischan, $thisuser, $thismsg) = @_;
  return undef unless $thismsg =~ m/(?:
		^:?date |
		what\s+time\s+is\s+it\s*\?? |
		ya+wn |
		it'?s\s+(?:too)?\s*(?:late|early)
	)/xi;
  utility::spew( $thischan, $thisuser, "$thisuser, ".scalar localtime(time()) );
}

sub private {
	do_date(@_)
}

sub public {
	do_date(@_)
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, ":date returns the current date on the bot's host." );
}
