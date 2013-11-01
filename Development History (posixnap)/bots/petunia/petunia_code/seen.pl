code
# lookup when a user was last here
sub seen {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return "seen" if @_ == 0;
	# petunia, seen uncreative?
	# :seen uncreative?
	# seen uncreative, petunia?
	return unless $thismsg =~ /^
		(?: :seen\s+([^? ]+)\?? |
		$mynick,?\s+seen\s*([^? ]+) |
		(?:seen\s+)?([^?, ]+),?\s+$mynick\?? )
	/xi;
	my $victim = $1 || $2 || $3;
	return unless $victim and length $victim >= 3;
	return 0 if $victim =~ /$mynick/i;
	my $sth = $dbh -> prepare(qq{
		select who, quip, stamp from log where who ~* ?
			order by stamp desc limit 1
	});
	$sth -> execute($victim);
	my ($who, $quip, $stamp) = map { @{ $_ } } @{ $sth -> fetchall_arrayref() };
	if ($who && $quip && $stamp) {
		use Date::Calc qw{ Delta_YMDHMS };
		my @epoch = (localtime($stamp))[5,4,3,2,1,0];
		my @delta = (localtime(time()))[5,4,3,2,1,0];
		$delta[0] += 1900; # heh! 19100!
		$epoch[0] += 1900;
		$delta[1] += 1;
		$epoch[1] += 1; # this module sucks ASS.
		# trickery!! 
		my @names = qw{ 0years 1months 2days 3hours 4minutes 5seconds };
		my %deltas = map { scalar shift @names => $_ } Delta_YMDHMS(@epoch, @delta);
		my $uptime = "";
		foreach my $time_element (sort keys %deltas) {
			if ($deltas{$time_element}) {
				$uptime .= "$deltas{$time_element} ";
				$time_element =~ s/\d//g;
				$uptime .= "$time_element ";
			}
			else { next }
		}
		$nap -> public_message( "$who was seen $uptime ago saying '$quip'" );
		return 1;
	}
	else {
		$nap -> public_message( "no, i havent seen $victim" );
		return 0;
	}
}

(1 row)
