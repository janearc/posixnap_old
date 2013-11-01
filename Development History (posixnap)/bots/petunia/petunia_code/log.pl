code
sub log {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "log" if @_ == 0;
	my $sth = $dbh -> prepare(qq{
		insert into log (who, channel, quip, stamp)
			values (?, ?, ?, ?)
	});
	$sth -> execute($thisuser, $thischan, $thismsg, time());
	undef $sth;
}

(1 row)
