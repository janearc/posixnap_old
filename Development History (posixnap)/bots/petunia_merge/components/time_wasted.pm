use warnings;
use strict;

use DBI;
our $tw_dbh;
our ($delete_sth, $insert_sth, $update_sth, $check_sth, $age_sth);
our @DSN;
our %CONFIG;

# init, this initializes the stuff we need to do on a continual basis
sub init {
	my ($kernel) = shift;
	my ($dsn, $config) = (@_);
	@DSN = @{ $dsn };
	%CONFIG = %{ $config };
	$tw_dbh = init_dbh();
	init_handles();
}

# we're doing everything locally because of asynchronous IO
sub init_dbh {
	die "\@DSN not populated\n" unless defined @DSN;
	my $dbh = DBI -> connect( @DSN )
		or die DBI -> errstr();
	return $dbh;
}

sub init_handles {
	$delete_sth = $tw_dbh -> prepare(qq{
		delete from irc_joins where upper(who) = upper(?) and upper(channel) = upper(?)
	});
	$insert_sth = $tw_dbh -> prepare(qq{
		insert into irc_joins (who, channel, stamp)
			values (?, ?, now())
	});
	$update_sth = $tw_dbh -> prepare(qq{
		update irc_joins set stamp = now(), who = ?, channel = ?
			where upper(who) = upper(?) and upper(channel) = upper(?)
	});
	$check_sth = $tw_dbh -> prepare(qq{
		select stamp from irc_joins 
			where upper(who) = upper(?) and upper(channel) = upper (?)
	});
	$age_sth = $tw_dbh -> prepare(qq{
		select date_trunc('second', age((stamp), now())) from irc_joins
			where upper(who) = upper(?) and upper(channel) = upper(?)
	});
	q/true/;
}

sub public {
	my ($thischan, $thisuser, $thismsg) = (@_);
	if ($thismsg =~ /^:tw ?/) {
		$age_sth -> execute($thisuser, $thischan);
		my ($age) = map { @{ $_ } }  @{ $age_sth -> fetchall_arrayref() };
		if ($age) {
			utility::spew($thischan, $thisuser, "$thisuser has wasted $age since joining $thischan." );
		}
		else {
			utility::spew($thischan, $thisuser, "$thisuser has obviously spent too damn much time on $thischan" );
		}
		return;
	}
	return;
}

sub on_join {
	my ($thischan, $thisuser) = (@_);
	$check_sth -> execute( $thisuser, $thischan );
	my ($stamp) = map { @{ $_ } } @{ $check_sth -> fetchall_arrayref() };

	if ($stamp) {
		# we have seen them in this channel
		# yes, four times.
		$update_sth -> execute( $thisuser, $thischan, $thisuser, $thischan );
	}
	else {
		# we have not seen them in this channel
		$insert_sth -> execute( $thisuser, $thischan );
	}
}

# note caps
sub Join {
	my ($thischan, $thisuser, $thismsg, $kernel) = @_;
	on_join( $thischan, $thisuser );
	return;
}

sub part {
	my ($thischan, $thisuser, $thismsg, $kernel) = @_;
	# zap em from the table
	$delete_sth -> execute( $thisuser, $thischan );
}

# kick and part are the same result but they are different events from
# POCO::Irc's point of view.
sub kick {
	part( @_ );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "this module does not work." );
}

1;
