code
sub translation {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "translation" if @_ == 0;
  return 0 unless $thismsg =~ /^:(xlate|langs)/;

	###

  use WWW::Babelfish;
  my $fishy = new WWW::Babelfish;
	my @langs = $fishy -> languages();

	my %lang_hash = map {
		lc scalar substr ($_, 0, 2) => $_
	} @langs;

	###
	
	if ($1 =~ /^langs$/i) {
		$nap -> private_message($thisuser, "$_ => ".$lang_hash{$_})
			for keys %lang_hash;
		return 1;
	}

	my ($from, $to, $trans) = $thismsg =~ /^:xlate\s(\S+)\s(\S+)\s(.*)/;

	# allow shorthand in languages
	$from = $lang_hash{$from} || $from;
	$to = $lang_hash{$to} || $to;

	my $checker_sth = $dbh -> prepare(qq{
		select translation from translations 
			where fromlanguage = ? and tolanguage = ? and upper(trans_from) = upper(?)
	});

	my $seen; $checker_sth -> execute($from, $to, $trans);

	($seen) = map { @{ $_ } } @{ $checker_sth -> fetchall_arrayref() };

	# we've already translated this before
  if ($seen) {
		$nap -> public_message($seen." (cached)");
		return 1;
	}
	else {

  	my $output = $fishy -> translate(
			source => $from, destination => $to, text => $trans
		);
		if ($output =~ /&nbsp;/) {
			$nap -> public_message("Babelfish sucks ass.");
			return 0;
		}
		else {
			$nap -> public_message( $output );
			my $inserter = $dbh -> prepare(qq{
				insert into translations (fromlanguage, tolanguage, trans_from, translation)
					values (?, ?, ?, ?)
			});
			$inserter -> execute($from, $to, $trans, $output);
			return 1;
		}

		return 0;
	}

}

(1 row)
