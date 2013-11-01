use warnings;
use strict;

my $quiet_dbh = ${ utility::new_dbh_handle() };

my $avg_chatter_sth = $quiet_dbh -> prepare(qq{
	select avg(count) from quiet where channel = lower(?)
});

my $tod_chatter_sth = $quiet_dbh -> prepare(qq{
	select count(quip) from log
		where substr( date_trunc( 'day', stamp ), 1, 10 ) = substr( date_trunc( 'day', now() ), 1, 10 )
		and channel = lower( ? )
});

sub avg_chatter {
	my $channel = shift;

	$avg_chatter_sth -> execute( $channel );
	my ($avg) = map { @{ $_ } } @{ $avg_chatter_sth -> fetchall_arrayref() };

	return $avg + .00001; # no div by zero, please
}

sub today_chatter {
	my $channel = shift;

	$tod_chatter_sth -> execute( $channel );
	my ($tod) = map { @{ $_ } } @{ $tod_chatter_sth -> fetchall_arrayref() };

	return $tod + .00001; # no div by zero, please
}

sub public {
	my ($thischan, $thisuser, $thismsg) = @_;

	if ($thismsg =~ m/(?:
		(?:^:quiet)|
		it'?s\s+quiet($|in\s+here(?:today)?|today)
	)/x) {
		my $avg = avg_chatter( $thischan );
		my $today = today_chatter( $thischan );
		my $diff = $today / $avg;
		my $pct = sprintf "%5.2f", $diff;
		print "Traffic in $thischan is at $pct today.";
	}
	else {
		return;
	}
}

sub emote {
	()
}

sub private {
	()
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "don't ask, don't tell" );
}

1;
