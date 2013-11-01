code
sub infobot_nois {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "infobot_nois" if @_ == 0;
	return unless $thismsg =~ /^no,? $mynick,? (.+?)\s+(?:is|are)\s+(.+)$/i;
	my ($term, $definition) = ($1, $2);
	warn "'$1' '$2'\n";
	my $extant_sth = $dbh -> prepare(qq{
		select term, definition from infobot where upper(term) = upper(?)
	});
	$extant_sth -> execute($term);
	if (my ($href) = $extant_sth -> fetchall_arrayref({}) -> [0]) {
		my $insert_sth = $dbh -> prepare(qq{
			update infobot set definition = ? where upper(term) = upper(?)
		});
		$insert_sth -> execute($definition, $term);
		$nap -> public_message( "fine then, $thisuser" );
		return 1;
	}
	else {
		$nap -> public_message("what the hell are you talking about, $thisuser?");
		return 0;
	}
	return 0;
}

(1 row)
