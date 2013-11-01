code
sub ucfirst_words {
	my $in = shift;
	return join " ", map ucfirst(lc $_), (split /\s+/, $in);
}

(1 row)
