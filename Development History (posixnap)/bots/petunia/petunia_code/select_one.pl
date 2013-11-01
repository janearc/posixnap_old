code
sub select_one {
	my $query = shift;
	my $local_sth = $dbh -> prepare($query);
	$local_sth -> execute();
	my ($result) = map { @{ $_ } } @{ $local_sth -> fetchall_arrayref() };
	return defined $result ? $result : undef;
}

(1 row)
