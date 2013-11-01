use warnings;
use strict;

our $async = "yes please";

use utility::auth;

use DBI;
our $aop_dbh;
our $mynick;
our @DSN;
our %CONFIG;
our ($checkline_sth, $max_length_sth, $all_sth);

# init, this initializes the stuff we need to do on a continual basis
sub init {
	my ($kernel) = shift;
	my ($dsn, $config) = (@_);
	@DSN = @{ $dsn };
	%CONFIG = %{ $config };
	$aop_dbh = init_dbh();
	init_handles();
	$mynick = $CONFIG{nick};
}

# we're doing everything locally because of asynchronous IO
sub init_dbh {
	die "\@DSN not populated\n" unless defined @DSN;
	my $dbh = DBI -> connect( @DSN )
		or die DBI -> errstr();
	return $dbh;
}

sub init_handles {
	$checkline_sth = $aop_dbh -> prepare(qq{
		select line from autoop where upper(channel) = upper(?)
	});
	$all_sth = $aop_dbh -> prepare(qq{
		select aop_id as id, line, who_added from autoop where upper(channel) = upper(?)
			order by length(line) desc
	});
	$max_length_sth = $aop_dbh -> prepare(qq{
		select max(length(line)) from autoop where upper(channel) = upper(?)
	});
	return 1;
}

sub get_ops {
	my $channel = shift;
	$checkline_sth -> execute($channel);
	my @lines = map { @{ $_ } } @{ $checkline_sth -> fetchall_arrayref() };
	return @lines;
}

sub display_ops {
	my $channel = shift;
	$max_length_sth -> execute( $channel );
	$all_sth -> execute( $channel );
	my ($length) = map { @{ $_ } } @{ $max_length_sth -> fetchall_arrayref() };
	my @lines = @{ $all_sth -> fetchall_arrayref({}) };
	my @output;
	foreach my $row (@lines) {
		my $line = $row -> {line};
		my $id = $row -> {id};
		my $who = $row -> {who_added};
		push @output, sprintf "[%4.4s] %-*.*s %-*.*s", ( $id, ($length, $length, $line), ($length, $length, $who) );
	}
	return @output;
}

sub oppable {
	my ($thischan, $fqun) = (@_);
	my @ops = get_ops( $thischan );
	my $op = 0;
	foreach (@ops) {
		utility::auth::test( $_, $fqun ) and $op++;
	}
	return $op;
}

sub op {
	my ($thischan, $fqun, $kernel) = (@_);
	my $thisuser = utility::auth::fqun_to_user( $fqun );
	$kernel -> post( $CONFIG{nick}, 'mode', "$thischan +o $thisuser" );
	return;
}
	

sub Join_auth {
	my ($thischan, $fqun, $thismsg, $kernel) = (@_);
	if (oppable( $thischan, $fqun )) {
		op( $thischan, $fqun, $kernel );
		utility::debug( "opped $fqun on $thischan" );
		return 1;
	}
	else {
		utility::debug( "$fqun not oppable on $thischan" );
		return 0;
	}
}

sub public {
	pub_parse( @_ );
}

sub auth_pub {
	auth_parse( @_ );
}

sub auth_parse {
	my ($thischan, $fqun, $thismsg, $kernel) = (@_);
	if ($thismsg eq "!oplist") {
		if (oppable($thischan, $fqun)) {
			my $thisuser = utility::auth::fqun_to_user( $fqun );
			foreach (display_ops( $thischan )) {
				utility::private_notice( $thischan, $thisuser, $_ );
			}
			return;
		}
		else {
			my $thisuser = utility::auth::fqun_to_user( $fqun );
			utility::spew( $thischan, $thisuser, "$thisuser, you are not a $thischan aop." );
		}
	}
	elsif ($thismsg eq "!op") {
		if (oppable( $thischan, $fqun )) {
			op( $thischan, $fqun, $kernel );
			utility::debug( "opped $fqun on $thischan" );
		}
		else {
			my $thisuser = utility::auth::fqun_to_user( $fqun );
			utility::spew( $thischan, $thisuser, "no way, sunshine." );
		}
	}
	else {
		return;
	}
}

sub pub_parse {
	my ($thischan, $thisuser, $thismsg) = (@_);
	if ($thismsg eq "!oplist") {
		return ; # this should be handled by auth_pub
	}
	elsif ($thismsg eq "!op") {
		return ; # this should be handled by auth_pub
	}
	else {
		return;
	}
}
