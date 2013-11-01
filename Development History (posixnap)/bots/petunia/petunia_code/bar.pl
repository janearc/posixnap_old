code
sub bar {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "bar" if @_ == 0;
	return unless $thismsg =~ /^:bar/;
	print "\tfoo\n";
}

(1 row)
