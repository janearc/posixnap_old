sub public {
	my $sexwords = q{pink|moist| lix|facial|fanny|willy|manties| head|wank|blow|eat out|horny|pubic|shaft|dripping|nipple|clit|bang|cunt|slit|wet|hard|rock|gay|fuck| ass|pussy|cock|dick|rod|hump|shag|carpet|munch|eating out|boobs|tits|melons|blowjob|porn|pr0n|pron|porno|friggin|eat me|balls|nuts|cum|suck|lick|bugger};
	my ($thischan, $thisuser, $thismsg) = @_;
  	my $command_string = qr{^(\!|\:)sexquote};
  	return undef unless $thismsg =~ $command_string;
	my ($user) = $thismsg =~ /^.sexquote\s+(.*)(\s+|)$/;
	my $select;
	if ($user) {
		$select = "where who ~* lower('$user') and quip ~ '$sexwords'" 
	} else {
		$select = "where quip ~ '$sexwords'";
	}
	my $quote = quote($user, $select);
	if ($quote->[1] =~ /^$/) {
		utility::spew($thischan, $thisuser, "No one named $user in my database.");
		return 0;
	}
	my $i;
	while (length($quote->[1]) < 10 && $i < 10) {
		$quote = quote($user, $select);
		$i++;
	}
	undef $i;
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
:sexquote username (or partial) will reveal the dirty things they've been saying.
HELP
}
sub quote {
	my ($user, $select) = @_;
	utility::debug( "select who, quip from log " . $select . " order by random() limit 1" );
	my $q_sth = ${ utility::new_dbh_handle() } -> prepare(
                "select who, quip from log
                " . $select . " order by random() limit 1"
        );
	$q_sth->execute();
	my $quote = $q_sth -> fetchall_arrayref() -> [0];
	return $quote;
}
1;
