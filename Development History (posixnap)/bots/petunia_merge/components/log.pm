sub do_log {
	my ($thischan, $thisuser, $thismsg) = @_;
	if( ref $thischan eq 'ARRAY' ) {
	    ($thischan) = @$thischan;
	}
	my $dbh = ${ utility::new_dbh_handle() };
	my $sth = $dbh -> prepare(qq{
		insert into log (who, channel, quip, stamp)
			values (?, ?, ?, now())
	});
	$sth -> execute($thisuser, $thischan, $thismsg);
}

sub public {
    do_log( @_ );
}

sub private {
}

sub emote {
    do_log( @_ );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) ,<<"HELP";
log is a passive sub and as such is not user controllable.
HELP
}

1;
