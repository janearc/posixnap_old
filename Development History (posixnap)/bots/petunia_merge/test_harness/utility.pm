package utility;

use warnings;
use strict;
use vars qw{ @db_handles $db_dsn $db_user $db_pass %config $epoch_start };
use Carp qw{ cluck croak carp };
use DBI;
use Broker::Config;
use Data::Dumper;

$epoch_start = time();

sub database_initialize {
	($db_dsn, $db_user, $db_pass)  = @_;
	my @dbi_params = (
		$db_dsn,
		$db_user,
		$db_pass,
	);
	# J: useless in test_harness
	#my $dbh = DBI -> connect(@dbi_params)
	#	or die DBI -> errstr;
	#push @db_handles, \$dbh; # no reason to waste one...

	
	1;
}

# Escape everything into valid perl identifiers
# this is stolen from mod_perl's Apache::Registry
sub id_ize {
    my ($script_name) = @_;
    $script_name =~ s/([^A-Za-z0-9_\/])/sprintf("_%2x",unpack("C",$1))/eg;
    
    # second pass cares for slashes and words starting with a digit
    $script_name =~ s{
	(/+)       # directory
	    (\d?)      # package's first character
	}[
	  "::" . (length $2 ? sprintf("_%2x",unpack("C",$2)) : "")
	  ]egx;
    $script_name;
}

sub public_spew {
	return unless $_[2];
	print "public_spew: [ @_ ]\n";
}

sub spew {
	return unless $_[2];
	print "spew: [ @_ ]\n";
}

sub private_spew {
	return unless $_[2];
	print "private_spew: [ @_ ]\n";
}

sub debug {
	my ($package, $line, $subroutine) = ( caller(1) )[0, 2, 3];
	my ($prefix) = "$0: $subroutine [$line]: ";

	warn $prefix.$_[0].$/;
}

sub new_dbh_handle {
	my $dbh = DBI -> connect( $db_dsn, $db_user, $db_pass )
		or debug( "ACK! new_dbh_handle: sorry, no database connection for you! ".DBI -> errstr() );

	# the first time we connect is when we're tie'ing %config, so either
	# check that %config's been defined, set a flag, or live with the
	# warning.
	if (defined(%config) and $#db_handles > 2) {
		my $this_dbh = $db_handles[0];
		return $this_dbh;
	}
	push @db_handles, \$dbh;
	return \$dbh;
}

1;
