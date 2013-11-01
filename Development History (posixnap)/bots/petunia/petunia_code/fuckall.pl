code
sub fuckall {
	my ($thisuser, $thischan, $thismsg) = (@_);
	return unless $thismsg eq ":fuckall" ;
	my $fuck = $dbh -> prepare("select name from subs"); $fuck -> execute();
	load_sub("whatever", $thisuser, ":load $_") for map { @{ $_ } } @{ $fuck -> fetchall_arrayref() };
	return 1;
}

(1 row)
