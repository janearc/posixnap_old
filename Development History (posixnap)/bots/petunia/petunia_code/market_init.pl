code
sub market_init {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "market_init" if @_ == 0;
	#chomp $thismsg; # not necessary in the bot.
	return unless $thismsg =~ /^:minit yes$/;
	my $sth;
	$sth = $dbh -> prepare(qq{
		delete from stocks where owner = ?;
		delete from profits where who = ?;
		insert into profits (who, profit) values (?, ?);
	});
	$sth -> execute($thisuser, $thisuser, $thisuser, 10000);
	$nap -> public_message( "welcome to the stock market, $thisuser, you've got \$10,000!" );
	return 1;
}

(1 row)
