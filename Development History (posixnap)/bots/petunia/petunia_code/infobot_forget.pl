code
sub infobot_forget {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "infobot_forget" if @_ == 0;
	return unless $thismsg =~ /^$mynick,?\s+forget\s+(.+?)[.!?,]?$/;
	my ($term) = ($1);
	my $extant_sth = $dbh -> prepare(qq{
		select term, definition from infobot where upper(term) = upper(?)
	});
	$extant_sth -> execute($term);
	if (my $extant = $extant_sth -> fetchall_arrayref() -> [0] -> [0]) {
		my $delete_sth = $dbh -> prepare(qq{
			delete from infobot where upper(term) = upper(?)
		});
		$delete_sth -> execute($term);
		$nap -> public_message("okay, $thisuser, i forgot about $term.");
		return 1;
	}
	else {
		$nap -> public_message( "uhhh, $term?" );
		return 0;
	}
	return 0;
}

(1 row)
