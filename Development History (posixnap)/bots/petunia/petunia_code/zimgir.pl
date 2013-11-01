code
sub zimgir {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "zimgir" if @_ == 0;
	return 0 unless $thismsg =~ /^:(zim|gir)/i;
	my $table = lc($1);
	my $q_sth = $dbh -> prepare(
		"select quote from ".$table."_quotes order by random() limit 1"
	);
	$q_sth -> execute();
	my $quote = $q_sth -> fetchall_arrayref() -> [0] -> [0];
	$nap -> public_message($quote);
	return 1;
}

(1 row)
