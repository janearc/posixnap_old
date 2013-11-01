code
sub lineitemveto {
	return 0 if $_[0] =~ /^#/;
	my $rowcount = 1;
	my ($toobig, $private, $nick) = (@_);
  use Text::Wrapper;
  my $wrapper = Text::Wrapper -> new();
  $wrapper -> columns(75);
	$toobig = $wrapper -> wrap($toobig);
	my @lines = split /(?:\n|\n\r|\r\n|\r\r)/, $toobig;
	foreach my $line (@lines) {
		if ($private and $private =~ /private/i) {
			$nap -> private_message($nick, $line);
		}
		else {
			$rowcount++;
			$nap -> public_message($line);
		}
		if ($rowcount >= 5) {
			$nap -> private_message($nick, "you produced more than 5 lines of output.");
			return 1;
		}
	}
	if ($rowcount = @lines) { return 1 }
	else {
		warn "lineitemveto: unsuccesful [ @_ ]\n";
		return 0;
	}
}

(1 row)
