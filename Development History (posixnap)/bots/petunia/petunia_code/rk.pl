code
# return two random items and their relation from karma
sub rk {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "rk" if @_ == 0;
	return unless $thismsg =~ /^:rk/;
	my $sth = $dbh -> prepare(qq{
		select item, value from karma order by random() limit 2
	});
	$sth -> execute();
	my ($item, $value) = @{ $sth -> fetchrow_arrayref() };
	my ($item2, $value2) = @{ $sth -> fetchrow_arrayref() };
	if ($value > $value2) {
		$nap -> public_message( "$item is cooler than $item2" );
	}
	elsif ($value == $value2) {
		$nap -> public_message( "$item2 is as cool as $item" );
	}
	else {
		$nap -> public_message( "$item2 is cooler than $item" );
	}
}

(1 row)
