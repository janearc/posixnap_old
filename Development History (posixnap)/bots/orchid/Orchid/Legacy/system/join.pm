use warnings;
use strict;

my $join_dbh = ${ utility::new_dbh_handle() };
my $push = $join_dbh -> prepare(qq{
	insert into channels (channel) values (?)
});
my $pull = $join_dbh -> prepare(qq{
	select channel from channels
});

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
join.pm is not authorized for non maintainer users.
HELP
}

sub do_join {
	my ($thischan, $thisuser, $thismsg, $kernel) = (@_);
	my ($chan) = $thismsg =~ /AUTH: join (#\S+)/;
	return unless $chan;
	if (defined $kernel) {
		$kernel -> post( $utility::config{nick}, 'join', $chan );
		utility::spew( $thischan, $thisuser, "tried to join $chan" );
		$push -> execute( $chan );
	}
	else {
		utility::spew( $thischan, $thisuser, "fuck, kernel missing!" );
	}
}

sub public {
	();
}

sub private {
	do_join( @_ );
}

sub init {
	my $kernel = shift;
	$pull -> execute();
	foreach my $channel (map { @{ $_ } } @{ $pull -> fetchall_arrayref() }) {
		$kernel -> post( $utility::config{nick}, 'join', $channel );
	}
}
