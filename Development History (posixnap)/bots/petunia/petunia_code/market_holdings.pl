code
sub market_holdings {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "market_holdings" if @_ == 0;
	return unless $thismsg =~ /^:holdings/;
	my $fetcher = $dbh -> prepare(qq{
		select owner, stock, initial_price, shares from stocks where owner = ?
	});
	$fetcher -> execute($thisuser);
	my @rows = @{ $fetcher -> fetchall_arrayref() };
	if (@rows == 0) {
		$nap -> private_message($thisuser, "try again, $thisuser... or do :minit yes if youd like to start playing" );
		return 0;
	}
	else {
		my $psnatch = $dbh -> prepare(qq{
			select profit from profits where who = ?
		});
		$psnatch -> execute($thisuser);
		my $profits = $psnatch -> fetchall_arrayref() -> [0] -> [0];
		$nap -> private_message($thisuser,  "You've got \$$profits, $thisuser" );
		use Finance::Quote;
		foreach my $row (@rows) {
			my ($owner, $stock, $initial_price, $shares) = @{ $row };
			return 0 unless ($owner && $stock && defined $initial_price && defined $shares);
			my $query = Finance::Quote -> new();
			my %quote = $query -> yahoo($stock);
			my $new_cost = $quote{$stock, "last"};
			$nap -> private_message($thisuser,  "$stock -> $shares @ $initial_price [ now: $new_cost ]" );
		}
	}
}

(1 row)
