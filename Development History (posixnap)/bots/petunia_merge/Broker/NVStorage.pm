package Broker::NVStorage;

#
# NVStorage.pm
#
# Class for nonvolatile storage of data. Allows volatile programs
# to store data similar to the 'static' data in pascal.
#

# currently implemented as a hash. database routines to follow.

use strict;
use warnings;
use Data::Dumper;

use Storable qw{ nfreeze thaw };
use DBI;
use POE;
use POE::Session;
use POE::Kernel;

our ($MAX_LATENCY);
$MAX_LATENCY = 15;

my %STORES = ();
my %L_STORES = ();

sub new {
	my $dbh = ${ utility::new_dbh_handle() };
	return bless { dbh => \$dbh }, shift();
}

sub nv_store {
	my ($self, $requested_key, $data) = (@_);

	my ($pkg) = ( caller( 1 ) )[ 3 ] =~ /([^:]+)::/;
	my $record = $pkg."'".$requested_key;
	
	utility::debug( "overwriting data for $record" ) if $STORES{ $record };
	(utility::debug( "was not passed a reference for $record" ) 
		and return undef) unless ref $data;
	_link_store( $record );
	$STORES{ $record } = nfreeze( $data );
	
	return 1;
}

sub nv_retrieve {
	my ($self, $requested_key) = (@_);

	my ($pkg) = ( caller( 1 ) )[ 3 ] =~ /([^:]+)::/;
	my $record = $pkg."'".$requested_key;

	utility::debug( "no data found for $record" ) unless $STORES{ $record };
	_link_retrieve( $record );
	my $local_data = \thaw( $STORES{ $record } );
	return $local_data;
}

sub nv_records {
	my ($self) = (@_);

	my ($pkg) = ( caller( 1 ) )[ 3 ] =~ /^([^:]+)::/;

	my @keys = grep { /^$pkg/ } keys %STORES;

	return \@keys;
}

sub _link_store {
	my $KEY = shift;
	$L_STORES{ $KEY } = {} unless $L_STORES{ $KEY };
	$L_STORES{ $KEY } -> {stored} = time();
	return 1;
}

sub _link_retrieve {
	my $KEY = shift;
	$L_STORES{ $KEY } = {} unless $L_STORES{ $KEY };
	$L_STORES{ $KEY } -> {retrieved} = time();
	return 1;
}

sub _link_written {
	my $KEY = shift;
	$L_STORES{ $KEY } = {} unless $L_STORES{ $KEY };
	$L_STORES{ $KEY } -> {written} = time();
	return 1;
}

sub _cache_maint {
	my $kernel = shift;
	
	foreach my $KEY (keys %L_STORES) {
		my $latency = time() - ($L_STORES{ $KEY } -> {written});
		if ($latency > $MAX_LATENCY) {
			_cache_write( $KEY );
			_link_written( $KEY );
			utility::debug( "stored $KEY" );
		}
		next; # it was not old enough, keep it.
		# XXX: add a collector here.
	}

	my $alarm_id = $kernel -> delay_set( '_cache_maint', $MAX_LATENCY, );
}

sub _cache_write {
	return 0; # XXX: this needs MAJOR testing right now.
	my $KEY = shift;
	if (ref $KEY) { # $obj -> _cache_write()
		utility::debug( "you may not use this function, it is private for this class." );
	}
	if (not length $KEY) {
		utility::debug( "key was empty!" );
	}

	# ok, we have a valid key. lets write it.

	# grab a dbh.
	my $write_dbh = ${ utility::new_dbh_handle() };

	# grab the data.
	my $data = $STORES{ $KEY };

	# ensure we have a key for this data already
	my $extnt_sth = $write_dbh -> prepare(qq{
		select count (recordname) from nv_storage where recordname = ?
	});
	$extnt_sth -> execute();
	# check to see if recordname is extant. insert if not, update otherwise.
	my $write_sth = $write_dbh -> prepare( (map { @{ $_ } } @{ $extnt_sth -> fetchall_arrayref() } )[0] ? qq{
		update nv_storage set data = ? where recordname = ?
	}:qq{
		insert into nv_storage (data, recordname)
			values (?, ?)
	});
	
	# shove it baby...
	$write_sth -> execute( $data, $KEY );
	1;
}

1;
