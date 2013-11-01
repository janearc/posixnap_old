code
sub tliv {
	my ($thischan, $thisuser, $thismsg) = @_;
	return "tliv" if @_ == 0;
	if ($thismsg =~ /^:tliv /) {
		my ($msg) = $thismsg =~ /^:tliv (.*)/;
		lineitemveto($msg);
		if ($@) {
			$nap -> public_messag($@);
		}
	}
	return 1;
}

(1 row)
