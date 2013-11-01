## karma.pm
## the most often-used module. simply increments and decrements
## variables in the 'karma' table.

use warnings;
use strict qw{ subs vars };
use DBI;

use constant KARMA_EXISTS => 1;
use constant UNSPECIFIED_ERROR => 5;
use constant SUCCESS => 255;

our $krm_dbh;
our $mynick;
our @DSN;
our %CONFIG;

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::private_spew( $thischan, $thisuser, <<"HELP"
:karma  Return the karma of the given item.
item++  Increments the karma of item.
item--  Decrements the karma of item.
(item with spaces)-- or (item with spaces)++ increments or decrements an item with spaces.
:merge parent child
        Adds the value of child to parent, then deletes child.
:rk     Compares the karma of two random items. If an item was given, compare it with a random item.
:kf     (item) (another item) fights two items
HELP
	);
}

# init, this initializes the stuff we need to do on a continual basis
sub init {
	my ($kernel) = shift;
	my ($dsn, $config) = (@_);
	@DSN = @{ $dsn };
	%CONFIG = %{ $config };
	$krm_dbh = init_dbh();
	$mynick = $CONFIG{nick};
}

# we're doing everything locally because of asynchronous IO
sub init_dbh {
	die "\@DSN not populated\n" unless defined @DSN;
	my $dbh = DBI -> connect( @DSN )
		or die DBI -> errstr();
	return $dbh;
}

# karma.pm has the following conventions:
#   1.	Subs are named after their keys, i.e. "KEY" corresponds to karma_KEY()
#   2.	Any capturing is done within the %dispatcher regex
#		3.	A ref to the captures is passed as the 4th argument to karma_KEY()
sub do_karma {
	my ($thischan, $thisuser, $thismsg) = (@_);

	my %dispatcher = (
		lookup	    => qr{
			(?:
				^:(?:karma|score)|
				$mynick,\s+(?:karma|score)
			) 
			\s+ 
			(
				[\d\w_]+|
				\([\w\s]+\)
			)
		}ix,
		decrement		=> qr{
			(
				[\d\w_]+|
				\([\w\s]+\)
			)--
		}ix,
		increment		=> qr{
			(
				\w+|
				\([\w\s()]+\)
			)\+\+
		}ix,
		merge				=> qr{^:merge ([^\s()]+) (.+)}i,
		rk					=> qr{^:rk\s*$}i,
		compare			=> qr{
			^:rk\s+
			(
				[\d\w_]+|
				\([\w\s]+\)
			)
		}ix,
		fight				=> qr{
			^:kf\s+
				(
					[\d\w_]+|
					\([\w\s]+\)
				)
				\s+
				(
					[\d\w_]+|
					\([\w\s]+\)
				)
		}ix,
	);

	foreach my $KEY (keys %dispatcher) {
		my $key = $dispatcher{ $KEY };
		if ( my( @captures ) = $thismsg =~ /$key/g ) {
			&{ __PACKAGE__ . "::karma_$KEY" }
			( $thischan, $thisuser, $thismsg, \@captures );
		}
	}
}


# decrement an item's karma value 
sub karma_decrement {
    my ($thischan, $thisuser, $thismsg, $captref) = (@_);
    my $item = $captref -> [0];
    if (karma_exists( $item ) -> [0]) {
	# item exists, remove it.
	my $decrement_sth = $krm_dbh -> prepare(q{
	    update karma set value = value - 1 where item = ?
	});
	$decrement_sth -> execute( $item );
	return SUCCESS;
    }
    else {
	# they do not exist, add them
	my $insert_neg_sth = $krm_dbh -> prepare(q{
	    insert into karma(item, value) values( ?, -1 )
	});
	$insert_neg_sth -> execute( $item );
	return SUCCESS;
    }
    return UNSPECIFIED_ERROR;
}

# increment an item's karma value
sub karma_increment {
    my ($thischan, $thisuser, $thismsg, $captref) = (@_);
    my $item = $$captref[0];
    my $value = lc $item eq lc $thisuser ? -1 : 1; # cannot increment yourself
    if (karma_exists( $item ) -> [0]) {
	# we have a value in karma already, increment it
	my $increment_sth = $krm_dbh -> prepare( q/
	    update karma set value = value + ? where lower(item) = lower(?)
	/);
	$increment_sth -> execute($value, $item);
	return SUCCESS;
    }
    else {
	# this is a new value, insert it
	my $insert_pos_sth = $krm_dbh -> prepare( q/
	    insert into karma (item, value) values (?, ?)
	/);
	$insert_pos_sth -> execute($item, $value);
	return SUCCESS;
    }
    return UNSPECIFIED_ERROR;
}


# sometimes stuff gets stuffed into karma like "school" and "lack of work"
# it was deemed necessary to be able to merge them into one record.
sub karma_merge {
    my ($thischan, $thisuser, $thismsg, $captref) = (@_);
    my ($parent, $child) = @$captref;

    my ($exists, $pval) = @{ karma_exists( $parent ) };

    if ( $exists ) {
	# we have seen the parent.

	($exists, my $cval) = @{ karma_exists( $child ) };
	if ( $exists ) {
	    # we have also seen the child.

	    # update the karma for the parent
	    # Seems to me we should sum the values, no?
	    my $mrg_sth = $krm_dbh -> prepare(qq{
		update karma set value = ? where item = ?
	    });
	    $mrg_sth -> execute( $pval + $cval, $parent );

	    # delete the child since the parent has inherited the karma from 
	    # the child.
	    my $del_sth = $krm_dbh -> prepare(qq{
		delete from karma where item = ?
	    });
	    $del_sth -> execute( $child );

	    utility::spew( $thischan, $thisuser,
		"karma merged $parent ($child)" );
	    return SUCCESS;
	}
	else {
	    # we havent seen the child.
	    utility::spew( $thischan, $thisuser,
		"no karma item found for $child, try using :karma..." );
	    return SUCCESS;
	}
    }
    else {
	# we havent seen the parent.
	utility::spew( $thischan, $thisuser,
	    "no karma item found for $parent, try using :karma..." );
	return SUCCESS;
    }
    return UNSPECIFIED_ERROR;
}


# look up a user's karma value in the table.
sub karma_lookup {
    my ($thischan, $thisuser, $thismsg, $captref) = (@_);
    my $item = $captref -> [0];
    my( $exists, $karma ) = @{ karma_exists( $item ) };
    if ( $exists ) {
	utility::spew( $thischan, $thisuser, "$item has $karma karma" );
	return SUCCESS;
    }
    else {
	utility::spew( $thischan, $thisuser, "$item has neutral karma" );
	return SUCCESS;
    }
    return UNSPECIFIED_ERROR;
}

sub karma_fight {
	my ($thischan, $thisuser, $thismsg, $captref)  = (@_);
	my ($challenger, $defender) = @{ $captref };
	warn "$challenger vs $defender\n";
	my ($e, $c_score, $d_score, $winner, $loser);
	($e, $c_score) = @{ karma_exists( $challenger ) };
	($e, $d_score) = @{ karma_exists( $defender ) };
	if (not $e) {
		# XXX: the fact that this is a hack indicates
		# that we should probably work on a standard karma lib.
		# other modules would probably like to use it, and i would
		# imagine it can now be considered a "core function" of the
		# bot, as silly as it seems.
		karma_decrement( "", "", "", [ $thisuser ] ); # ok, its a hack. sue me.
		utility::spew( $thischan, $thismsg, "$thisuser enters the karma arena without a weapon and loses 1 karma." );
		return;
	} 
	else {
		# both exist, lets fight em
		if ($c_score > $d_score) {
			$loser = $defender;
			$winner = $challenger;
		}
		elsif ($c_score < $d_score) {
			$loser = $challenger;
			$winner = $defender;
		}
		elsif ($c_score == $d_score) {
			utility::spew( $thischan, $thisuser, "$defender kicks $thisuser\'s ass" );
			return;
		}

		my $announce;

		if (int rand(10) + 1 > 7) {
			$announce = "$winner wins";
			$announce .= "... FATALITY!";
			if (int rand(10) + 1 > 7) {
				$announce .= " FLAWLESS VICTORY!";
				$announce .= "\n$loser loses 2 karma.";
				karma_decrement( "", "", "", [ $loser ] ); # ok, its a hack. sue me.
				karma_decrement( "", "", "", [ $loser ] ); # ok, its a hack. sue me.
				utility::spew( $thischan, $thisuser, $announce ); # fatality, flawless victory.
				return;
			}
			karma_decrement( "", "", "", [ $loser ] ); # ok, its a hack. sue me.
			utility::spew( $thischan, $thisuser, $announce ); # no FV, but fatality.
			return;
		}
		elsif (int rand(10) + 1 > 6) {
			$announce .= "$loser was seriously wounded, but THE SOUL STILL BURNS!";
			utility::spew( $thischan, $thisuser, $announce ); # nothing special here...
			return;
		}
		else {
			utility::spew( $thischan, $thisuser, "$winner wins." );
			return;
		}
	}
	return;
}

sub karma_exists {
    my $item = shift;

	my $dupe_sth = $krm_dbh -> prepare(qq{
		select count(item) from karma where upper(item) = upper( ? )
	});
	$dupe_sth -> execute( $item );
	my ($count) = map { @{ $_ } } @{ $dupe_sth -> fetchall_arrayref() };
	if ($count > 1) {
		my $dedupe_sth = $krm_dbh -> prepare(qq{
			select sum(value) from karma where upper(item) = upper( ? )
		});
		$dedupe_sth -> execute( $item );
		my ($sum) = map { @{ $_ } } @{ $dedupe_sth -> fetchall_arrayref() };
		$dedupe_sth = $krm_dbh -> prepare(qq{
			delete from karma where upper(item) = upper( ? );
			insert into karma (item, value) values ( ?, ? );
		}); # yes, thats two statements.
		$dedupe_sth -> execute( $item, $item, $sum );
	}
	
    my $exists_sth = $krm_dbh -> prepare(qq{
	select value from karma where upper(item) = upper( ? )
    });
    $exists_sth -> execute( $item );
    my ($value) = map { @{ $_ } } @{ $exists_sth -> fetchall_arrayref() };

    return defined $value ? [KARMA_EXISTS, $value] : [undef, undef];
}

# return two random items and their relation from karma
sub karma_rk {
    my ($thischan, $thisuser, $thismsg) = (@_);

    my $krm_sth = $krm_dbh -> prepare(qq{
	select item, value from karma order by random() limit 2
    });
		# we return undef here because we cannot dereference something
		# if an error is returned with the following statement. that will
		# cause a die() with a warning, which we dont want.
    $krm_sth -> execute() or return undef; 
    my ($item, $value) = @{ $krm_sth -> fetchrow_arrayref() };
    my ($item2, $value2) = @{ $krm_sth -> fetchrow_arrayref() };

    spew_compare( $thischan, $thisuser, $item, $value, $item2, $value2);
    return SUCCESS;
}

# common code for karma_rk and karma_compare
sub spew_compare {
    my ($thischan, $thisuser, $item, $value, $item2, $value2) = (@_);
		my $howcool;
		if (abs($value - $value2) > 3) {
			$howcool = "way cooler";
		}
		else {
			$howcool = "cooler";
		}
    utility::spew( $thischan, $thisuser,
	$value > $value2
	    ? qq/$item is $howcool than $item2/
	    : $value == $value2
		? qq/$item is as cool as $item2/
		: qq/$item2 is $howcool than $item/,
    );
}

# compares karma of a given item with a random item
sub karma_compare {
    my ($thischan, $thisuser, $thismsg, $captref) = (@_);
    my $item = $$captref[0];

    my ($exists, $value) = @{ karma_exists( $item ) };
    $value = 0 unless defined $value;
    my $krm_sth = $krm_dbh -> prepare(qq{
	select item, value from karma order by random() limit 1
    });
    $krm_sth -> execute() or return undef;
    my ($item2, $value2) = @{ $krm_sth -> fetchrow_arrayref() } 
    		or return undef;
    spew_compare ($thischan, $thisuser, $item, $value, $item2, $value2);
    return SUCCESS;
}

sub public {
    do_karma( @_ );
}
