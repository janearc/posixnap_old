use warnings;
use strict;

our $seen_dbh = ${ utility::new_dbh_handle() }; # convention

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew($thischan, $thisuser, ":seen [ nick ] returns the date last seen and what they said.")
}

# lookup when a user was last here
sub seen {
	my ($thischan, $thisuser, $thismsg) = (@_);

	my $mynick = $utility::config{nick};
	# petunia, seen uncreative?
	# :seen uncreative?
	# seen uncreative, petunia?
	return unless $thismsg =~ /^
		(?: :seen\s+([^? ]+)\?? |
		$mynick,?\s+seen\s*([^? ]+)\? |
		(?:seen\s+)([^?, ]+),\s+$mynick\?? )
	/xi;
	my $victim = $1 || $2 || $3;
	return unless length $victim;
	return 0 if $victim =~ /$mynick/i;
	return 0 if $victim =~ /thanks/i;
	# this is the fastest damn seen sub we've ever, um, seen.
	# yay postgres.
	my $sth = $seen_dbh -> prepare(qq{
		select  
			who || ' was last seen saying ''' ||
			quip || ''' ' ||
			date_trunc('second', age((stamp), now())) || ' ago on ' || 
			channel || ' at ' || 
			date_trunc('second', stamp)
					from log where upper(who) = upper(?)
					order by stamp desc limit 1;
	});
	# from log where upper(who) = upper(?) group by who, quip, stamp, channel 
	$sth -> execute($victim);
	my ($string) = map { @{ $_ } } @{ $sth -> fetchall_arrayref() };
	if ($string) {
		$string =~ s/\s-(\d)/ $1/g;
		utility::spew( $thischan, $thisuser, $string );
		return 1;
	}
	else {
		utility::spew( $thischan, $thisuser, "no, i havent seen $victim" );
		return 1;
	}
}

sub public {
    seen( @_ );
}

sub private {
    seen( @_ );
}

sub emote {
}

1;
