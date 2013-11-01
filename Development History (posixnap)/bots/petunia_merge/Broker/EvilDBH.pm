package Broker::EvilDBH;

#
# EvilDBH.pm
#
# Class for live-switching database connections. The DSN
# is actually _stored_ in the database, and we want to be
# able to switch databases when that changes so we can adapt
# to the database server crashing. Thusly, we do not actually
# return a dbh, we return a _tied_ dbh, which knows when it
# is broken, and repairs itself with the dsn (or dies).
#
# The principle of "pretending" to be a dbh is just ... evil.
#

# currently implemented as a hash. database routines to follow.

use strict;
use warnings;
use Data::Dumper;
use Carp qw/confess/;

use DBI;


our @db_handles;
our %last_config = ();
our $last_dbh = 0;
#our %current_config;
our %config;
our $count = 0;



# hack. yuck.
# forces fetching prior to dereferencing (i hope).
no strict 'refs';
foreach my $method ( keys %{ "DBI::db::" } ) {
    if( *{"DBI::db::$method"}{CODE} and not *{__PACKAGE__."::$method"}{CODE} ) {
	eval qq/
	    sub $method {
		my \$self = shift;
		return \$self->FETCH->$method (\@_)
	   };/;
    }
}
use strict 'refs';



# this really is evil. we need to be passed a dbh. do we tell the user?
# would it really be evil if we told them that?
sub new {
    my $class = shift;
    my $self = $class->TIESCALAR(@_);
    return $self;
}


# set up %config and all other variables
sub _init {
    my @dbi_params = @_[0 .. 2];
    my $dbh = DBI -> connect(@dbi_params) or confess DBI -> errstr;
    
    @db_handles = (\$dbh);
    tie %config, 'Broker::Config', $dbh;

    %last_config = map { $_ => $config{$_} } qw/dsn db_user db_pass max_dbh/;
    utility::debug("initialised \%config settings");

    $last_dbh = -1; # will be incremented when we FETCH an old handle

    return 1;

}


# create and return a reference to a new dbh
sub _new_dbh {
    my $dbh = DBI->connect(@config{qw/dsn db_user db_pass/})
	or debug( "ACK! sorry, no database connection for you! "
	    . DBI->errstr() );
    push @db_handles, \$dbh;
    return \$dbh;
}


sub TIESCALAR {
    my $class = shift;
    my @args = @_;
    _init( @args ); # initialise if necessary
    ++$count;
    my $dummy;
    return bless \$dummy, $class;
}


sub FETCH {
    my $self = shift;
    my $dbh;

    # JZ: Perhaps making three db checks every time is excessive. Relying on
    # notify() only.

    # check whether the configuration's changed; if so, we need a new dbh
    #if( _check_config() ) {
	#_reinit();
	#$dbh = _new_dbh();
	# $#db_handles should always be one here
	#utility::debug("dirty; new handle allocated, $#db_handles existing");
    #}

    # we can reuse an old dbh
    #else {
	if( scalar @db_handles > $last_config{max_dbh} ) {
	    # increment (or wrap) $last_dbh, and use that handle
	    # the idea is to round-robin the handles
	    $dbh = $db_handles[++$last_dbh == $last_config{max_dbh}
		? $last_dbh = 0 : $last_dbh];
	    utility::debug("old handle $last_dbh reused");
	} else {
	    $dbh = _new_dbh();
	    utility::debug("new handle created, $#db_handles existing");
	}
    #}

    return $$dbh; # why? because we're not expecting a reference

}


sub STORE {
    confess 'no way sunshine: you can\' assign to EvilDBH.';
}


sub DESTROY {
    if( not --$count ) {
	foreach( @db_handles ) { $$_ and $$_ -> disconnect() }
	@db_handles = ();
	# we can't do this, since it relies on $config{admin_channel}
	#utility::debug("no more evil, all handles closed");
	print "*** all EvilDBH handles closed\n";
    }
}


# checks the validity of the last known db configuration, and returns an integer
# equalling the number of changed keys
sub _check_config {
    my $dirty;
    my %current_config;

    foreach( keys %last_config ) {
	$current_config{$_} = $config{$_};
	# is %last_config invalid?
	if( $current_config{$_} ne $last_config{$_} ) {
	    $dirty++;
	    $last_config{$_} = $current_config{$_};
	}
    }

    return $dirty;
}


# reinitialises the evil
sub _reinit {
    foreach( @db_handles ) { $$_ and $$_ -> disconnect() }
    _init( @last_config{qw/dsn db_user db_pass/} );
}


# we made some changes, update /now/ damnit! otherwise you'd have to wait until
# the next fetch.
sub notify {
    if( _check_config() ) {
	_reinit();
	utility::debug("dirty (manual notify)");
    }
}


1;
