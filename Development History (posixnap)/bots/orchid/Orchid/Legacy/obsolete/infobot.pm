##
## infobot.pm
##
## interface with the infobot fact lookup table via the
## chat driven interface from pelvis. again, common library
## here rather than separate modules for lookups, etc.
##

use warnings;

use constant INFOBOT_EXISTS => 1;
use constant SUCCESS => 255;

# this means we want to issue as few queries as possible against this table.
# goro_count: 420 wallclock secs (20.15 usr + 14.46 sys = 34.61 CPU) @ 28.89/s (n=1000)
# goro_lookup: 397 wallclock secs (21.21 usr + 17.87 sys = 39.08 CPU) @ 25.59/s (n=1000)

our $ibt_dbh = ${ utility::new_dbh_handle() };
our $mynick = $utility::config{nick};

sub public {
	my $rv;
	foreach ( \&infobot_lookup, \&infobot_add, 
			\&infobot_nois, \&infobot_forget) {
		$rv = $_->(@_);
		return $rv if defined $rv;
	}
	return;
}

sub private {
	return public(@_);
}

# look up a value in the infobot table
sub infobot_lookup {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg =~ /^($mynick,?\s+)([^?]+)\?/;
	# this is somewhat icky. however with the regex, it seems like
	# the only way to go.
	my $query = defined $2 ? $2 : $1;
	if (my ($definition) = infobot_exists( $query )) {
		utility::spew( $thischan, $thisuser, $definition );
		return SUCCESS;
	}
	elsif ($1 and $2 and not infobot_exists( $query )) {
		# this means we were directly addressed.
		# 
		utility::spew( $thischan, $thisuser, "havent a clue, $thisuser" );
		return SUCCESS;
	}
	else {
		return 1;
	}
}

# look up whether a term actually exists in the infobot table.
sub infobot_exists {
	my ($item) = shift();
	my $sth = $ibt_dbh -> prepare(qq{
		select definition from infobot where upper(term) = upper( ? )
	});
	$sth -> execute( $item );
	my ($extant);
	if (($extant) = map { @{ $_ } } @{ $sth -> fetchall_arrayref() } ) {
		return $extant;
	}
	else {
		return undef;
	}
	return undef;
}

sub infobot_add {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg =~ /^$mynick,? (.+?)\s+(?:is|are)\s+(.+)$/i;
	my ($term, $definition) = ($1, $2);
	warn "'$1' '$2'\n";
	my $extant_sth = $ibt_dbh -> prepare(qq{
		select term, definition from infobot where upper(term) = upper(?)
	});
	$extant_sth -> execute($term);
	if (my ($href) = $extant_sth -> fetchall_arrayref({}) -> [0]) {
		if (ref $href eq "HASH" and scalar keys %{ $href }) {
			utility::spew ($thischan, $thisuser, 
				"but ".$href -> {term} ." is ".$
				href -> {definition}. ", $thisuser...");
			return SUCCESS;
		}
		else {
			my $insert_sth = $ibt_dbh -> prepare(qq{
				insert into infobot (term, definition) values (?, ?)
			});
			$insert_sth -> execute($term, $definition);
	                utility::spew( $thischan, $thisuser,
				"roger, $thisuser" );
			return 1;
		}
		return SUCCESS;
	}
	return SUCCESS;
}

sub infobot_nois {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg =~ /^no,? $mynick,? (.+?)\s+(?:is|are)\s+(.+)$/i;
	my ($term, $definition) = ($1, $2);
	warn "'$1' '$2'\n";
	my $extant_sth = $ibt_dbh -> prepare(qq{
		select term, definition from infobot where upper(term) = upper(?)
	});
	$extant_sth -> execute($term);
	if (my ($href) = $extant_sth -> fetchall_arrayref({}) -> [0]) {
		my $insert_sth = $ibt_dbh -> prepare(qq{
			update infobot set definition = ? where upper(term) = upper(?)
		});
		$insert_sth -> execute($definition, $term);
		utility::spew( $thischan, $thisuser,"fine then, $thisuser" );
		return 1;
	}
	else {
                utility::spew( $thischan, $thisuser,"what the hell are you talking about, $thisuser?" );
		return SUCCESS;
	}
	return SUCCESS;
}

sub infobot_forget {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg =~ /^$mynick,?\s+forget\s+(.+?)[.!?,]?$/;
	my ($term) = ($1);
	my $extant_sth = $ibt_dbh -> prepare(qq{
		select term, definition from infobot where upper(term) = upper(?)
	});
	$extant_sth -> execute($term);
	if (my $extant = $extant_sth -> fetchall_arrayref() -> [0] -> [0]) {
		my $delete_sth = $ibt_dbh -> prepare(qq{
			delete from infobot where upper(term) = upper(?)
		});
		$delete_sth -> execute($term);
                utility::spew( $thischan, $thisuser,"okay, $thisuser, i forgot about $term." );
		return 1;
	}
	else {
                utility::spew( $thischan, $thisuser,"uhhh, $term?" );
		return SUCCESS;
	}
	return SUCCESS;
}
