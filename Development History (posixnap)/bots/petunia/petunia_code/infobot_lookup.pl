code
sub infobot_lookup {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "infobot_lookup" if @_ == 0;
	return unless $thismsg =~ /^($mynick,? )?([^?]+)\?/;
	my $query = $2;
	warn "'$1' '$2'\n";
	my $sth = $dbh -> prepare(qq{
		select definition from infobot where upper(term) = upper(?)
	});
	$sth -> execute($query);
	my $definition = $sth -> fetchall_arrayref() -> [0] -> [0];
	if ($definition) {
		$nap -> public_message( "$definition" );
	}
	elsif ($1 and !$definition) {
		# this means we were directly addressed.
		$nap -> public_message( "havent a clue, $thisuser" );
	}
	else {
		return 1;
	}
}

(1 row)
