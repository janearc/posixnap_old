sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
	my $command_string = qr{^\:quote};
	return undef unless $thismsg =~ $command_string;
	my ($regex) = $thismsg =~ /^\:quote\s+\w+\s+\/(\w+)(\/\w+|\/)$/;
	my ($user) = $thismsg =~ /^\:quote\s+(\w+)(\s+|.*|)$/;
	return 0 unless $user =~ /\w+/;
	my $sqlreg = "";
	$sqlreg = qq{and quip ilike '\%$regex\%'} if $regex;
	utility::debug("User => $user regex => $regex");
	my $q_sth = ${ utility::new_dbh_handle() } -> prepare(
		"select who, quip from log
                where who ilike '\%$user\%' $sqlreg order by random() limit 1"
        );
	$q_sth->execute();
	my $quote = $q_sth -> fetchall_arrayref() -> [0];
	utility::spew( $thischan, $thisuser, "<" . $quote->[0] . "> " . $quote->[1]);
	return 0;
}

sub emote {
	()
}

sub private {
	()
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
:quote username (or partial) will pull a random quote from the requested user.
HELP
}

1;
