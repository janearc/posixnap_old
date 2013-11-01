code
sub infobot_add {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "infobot_add" if @_ == 0;
	return unless $thismsg =~ /^$mynick,? (.+?)\s+(?:is|are)\s+(.+)$/i;
	my ($term, $definition) = ($1, $2);
	warn "'$1' '$2'\n";
	my $extant_sth = $dbh -> prepare(qq{
		select term, definition from infobot where upper(term) = upper(?)
	});
	$extant_sth -> execute($term);
	if (my ($href) = $extant_sth -> fetchall_arrayref({}) -> [0]) {
		if (ref $href eq "HASH" and scalar keys %{ $href }) {
			$nap -> public_message("but ".$href -> {term} ." is ".$href -> {definition}. ", $thisuser...");
			return 0;
		}
		else {
			my $insert_sth = $dbh -> prepare(qq{
				insert into infobot (term, definition) values (?, ?)
			});
			$insert_sth -> execute($term, $definition);
			$nap -> public_message("roger, $thisuser");
			return 1;
		}
		return 0;
	}
	return 0;
}

(1 row)
