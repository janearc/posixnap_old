code
sub market_buy {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "market_buy" if @_ == 0;
	return unless $thismsg =~ /^:buy (\d+) (\S+)/;

	use Finance::Quote;
	my $cashpuller = $dbh -> prepare(qq{
		select profit from profits where who = ?
	});
	$cashpuller -> execute($thisuser);
	my ($cash) = map { @{ $_ } } @{ $cashpuller -> fetchall_arrayref() };
	my $shares_bought = $1;
	my $stock_bought = uc($2);
	my $query = Finance::Quote -> new();
	my %quote = $query -> yahoo($stock_bought);

	return 0 unless $quote{$stock_bought, "last"};
	my $cost = $quote{$stock_bought, "last"} * $shares_bought;
	if ($cost > $cash) {
		$nap -> public_message( "Try making \$".abs($cost - $cash)." more, $thisuser" );
		return 0;
	}
	
	my $present_sth = $dbh -> prepare(qq{
		select count(owner) from stocks where stock = ?
			and owner = ?
	});
	$present_sth -> execute($stock_bought, $thisuser);
	my ($present) = map { @{ $_ } } @{ $present_sth -> fetchall_arrayref() };

	if ($present) {
		my $sth;
		$sth = $dbh -> prepare(qq{
			select initial_price, shares from stocks
				where owner = ? and stock = ?
		});
		$sth -> execute($thisuser, $stock_bought);
		my ($price_A, $quantity_A) = @{ $sth -> fetchall_arrayref() -> [0] };
		my $total_quantity = $quantity_A + $shares_bought;
		my $quantity_B = $shares_bought;
		my $price_B = $quote{$stock_bought, "last"};
		my $new_price = ($quantity_A / $total_quantity * $price_A) + ($quantity_B / $total_quantity * $price_B);

		$sth = $dbh -> prepare(qq{
			update stocks set shares = ?, initial_price = ?
				where owner = ? and stock = ?
		});
		$sth -> execute($total_quantity, $new_price, $thisuser, $stock_bought);
		$nap -> public_message( "$quantity_B shares of $stock_bought [ \@ \$$price_B ] added [ new price: \$$new_price ]" );
	}
	else {
		# just a straight insert
		my $sth = $dbh -> prepare(qq{
			insert into stocks (owner, stock, initial_price, shares)
				values (?, ?, ?, ?)
		});
		$sth -> execute($thisuser, $stock_bought, $quote{$stock_bought, "last"}, $shares_bought);
		$nap -> public_message( "ok, $thisuser, you just spent \$$cost on $shares_bought shares of ".
			$quote{$stock_bought, "name"} );
	}
	$cash -= $cost;
	my $sth = $dbh -> prepare(qq{
		update profits set profit = ? where who = ?
	});
	$sth -> execute($cash, $thisuser);
	$nap -> public_message( "\$$cash left, $thisuser" );
}

(1 row)
