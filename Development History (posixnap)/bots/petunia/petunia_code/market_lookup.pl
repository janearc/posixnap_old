code
sub market_lookup {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "market_lookup" if @_ == 0;
	return unless $thismsg =~ /^:ml (\S+)/;
	my $lookup = $1;

	my $sth = $dbh -> prepare(qq{
		select * from stocks where owner = ?
	});
	$sth -> execute($lookup);
	my (@rows) = @{ $sth -> fetchall_arrayref({}) };
	return 0 unless @rows;
	
	my $profit = 0; my $market_value;
	foreach my $rowHref (@rows) {
		my $bought_cost = $rowHref -> {initial_price};
		my $stock = $rowHref -> {stock};
		use Finance::Quote;
		my $query = Finance::Quote -> new();
		my %quote = $query -> yahoo($stock);
		my $new_cost = $quote{$stock, "last"} * $rowHref -> {shares};
		my $old_cost = $rowHref -> {initial_price} * $rowHref -> {shares};
		# this isnt necessarily going to be positive, and thus not always profit..
		$market_value += $new_cost;
		$profit += ($new_cost - $old_cost);
	}
	my $summer = $dbh -> prepare(qq{
		select sum(shares * initial_price) from stocks where owner = ?
	});
	my $casher = $dbh -> prepare(qq{
		select profit from profits where who = ?
	});
	$casher -> execute($lookup);
	$summer -> execute($lookup);
	my ($sum) = map { @{ $_ } } @{ $summer -> fetchall_arrayref() };
	my ($cash) = map { @{ $_ } } @{ $casher -> fetchall_arrayref() };
	my $mode = ($profit - $sum) > 0 ? "made" : "lost";
	$nap -> public_message( "$lookup has \$$market_value in assets, for which \$$sum was paid." );
	$nap -> public_message( "$lookup also has \$$cash in cash, or a net worth of \$".($cash + $market_value)."." );
}

(1 row)
