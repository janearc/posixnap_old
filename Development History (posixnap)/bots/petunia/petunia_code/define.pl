code
# the definition sub loosely adapted from perl slut.
sub define {
	my ($searchterm, $rem);
	my ($thischan, $thisuser, $thismsg) = (@_);
	if (@_ == 0) { return "define" }
	if ($thismsg !~ /^:define/i) { 
		return;
	}
	else {
		($searchterm, $rem) = $thismsg =~ /^:define\s+(\S+)([\s\S]+)/i;
	}

	$searchterm .= $rem if $rem;

	my $dejavu = select_one(qq{
		select count(definition) from dict
			where searchterm='$searchterm'
	});

	# it's cached...
	if ($dejavu) {
		my $definition = select_one(qq{
			select definition from dict
				where searchterm='$searchterm'
		});
		lineitemveto($definition, "private", $thisuser);
		return 1;
	}

	# at this point we've determined that we were meant to be called.
	# so $searchterm is our search term.
	$nap -> private_message($thisuser, "Uncached definition, querying server...");
	use Net::Dict;
	my $dict = Net::Dict -> new ('dict.org', Timeout => 5);
	my $outbound;
	if (my $result = $dict -> define($searchterm)) {
		foreach my $definition (@{ $result }) {
			my ($db, $def) = @{ $definition };
			lineitemveto($def, "private", $thisuser);
			$outbound .= $def;
		}
	} 
	else {
		$nap -> private_message ($thisuser, "Problems connecting to dict.org or no definition.");
		return 1;
	}
	my $sth = $dbh -> prepare(
		"insert into dict(searchterm, definition) values(?, ?)",
	);
	$sth -> execute($searchterm, $outbound);
	undef $sth; # DBI prefers handles be destroyed
	return 1;
}

(1 row)
