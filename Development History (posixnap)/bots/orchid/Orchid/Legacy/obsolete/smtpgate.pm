use warnings;
use strict;

use Broker::NVStorage;
use Net::SMTP;
use DBI;

our $sg_dbh;
our @DSN;
our %CONFIG;
our %lookup; # this should be done with nv_store, but nv_store isnt quite nonvolatile yet.

our $store = Broker::NVStorage -> new();

sub init {
	my ($kernel) = shift;
	my ($dsn, $config) = (@_);
	@DSN = @{ $dsn };
	%CONFIG = %{ $config };
	$sg_dbh = init_dbh();
	init_handles();
	populate_lookup();
}

sub init_dbh {
	die "\@DSN not populated\n" unless defined @DSN;
	my $dbh = DBI -> connect( @DSN )
		or die DBI -> errstr();
	return $dbh;
}

# create table smtp_gate ( 
#		recipient varchar(256) not null, 
#		thresh int min 3 not null default 3, 
#		mx varchar(256) not null default 'postoffice.posixnap.net' 
# )

sub populate_lookup {
	$recip_sth -> execute();
	# construct a hash of hashrefs, mapping users to their attributes
	%lookup = map @{ 
		$recip_info_sth -> execute( $_ );
		$_ => $recip_info_sth -> fetchall_arrayref({}) -> [0] 
	} map {
		@{ $_ } 
	} @{ $recip_sth -> fetchall_arrayref() };
}

sub init_handles {
	$recip_sth = $sg_dbh -> prepare(qq{
		select recipients from smtp_gate;
	});
	$recip_info_sth = $sg_dbh -> prepare(qq{
		select thresh, mx, address from smtp_gate where recipient = ?
	});
	$
	return 1;
}

sub public {
	my ($thischan, $thisuser, $thismsg) = (@_);
	foreach my $user (@users) {
		push @{ $store -> nv_store( $user ) }, (scalar localtime())." <$thisuser> $thismsg";
		ready_to_go( $user ) and purge( $user );
	}
}

# use case: :smtpgate --mx= --address= --threshold=
sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "please do not try to use this module yet." );
}
