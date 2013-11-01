use warnings;
use strict;

my $part_sth = ${ utility::new_dbh_handle() };
my $pop = $part_sth -> prepare(qq{
	delete from channels where upper(channel) = upper( ? )
});

sub do_part {
	my ($thischan, $thisuser, $thismsg, $kernel) = (@_);
	my ($chan) = $thismsg =~ /AUTH: part (#\S+)/;
	return unless $chan;
	if (defined $kernel) {
		$kernel -> post( $utility::config{nick}, 'part', $chan );
		utility::spew( $thischan, $thisuser, "tried to part $chan" );
		$pop -> execute( $chan );
	}
	else {
		utility::spew( $thischan, $thisuser, "fuck, missing kernel." );
	}
}

sub public {
	();
}

sub private {
	do_part( @_ );
}
