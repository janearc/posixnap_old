code
sub market_sell {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "market_sell" if @_ == 0;
	return unless $thismsg =~ /^:sell (\d+) (\S+)/;

	use Finance::Quote;
	my $shares_sold = $1;
	my $stock_sold = uc($2);
	my $query = Finance::Quote -> new();
	my %quote = $query -> yahoo($stock_sold);

	my $sth;
	$sth = $dbh -> prepare(qq{	
		select shares from stocks where owner = ? and stock = ?
	});
	
	$sth -> execute($thisuser, $stock_sold);
	my ($shares_owned) = map { @{ $_ } } @{ $sth -> fetchall_arrayref() };
	return 0 if $shares_sold > $shares_owned;

	my $sum = $quote{$stock_sold, "last"} * $shares_sold;
	my $profitizer = $dbh -> prepare(qq{
		update profits set profit = profit + ? where who = ? 
	});
	my $reducer = $dbh -> prepare(qq{
		update stocks set shares = ? where owner = ? and stock = ?
	});
	$profitizer -> execute($sum, $thisuser);
	$nap -> public_message("\$$sum being added to your pile of cash $thisuser");
	$reducer -> execute(($shares_owned - $shares_sold), $thisuser, $stock_sold);
	return 1;
}

(1 row)
