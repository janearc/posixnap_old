#
# quotes.pm
#
# evolved from zimgir.pm
#
#          Table "quotes"
#    Column  |  Type   | Modifiers 
#  ----------+---------+-----------
#   whose    | text    | 
#   quote    | text    | 
#   personal | boolean | 
#     
# ":<some valid_quote key>" queries db and prints 
# a random quote, prefixes with "$thisuser, " if personal is true
#
# %valid_quotes is initialized from the db on module load
# an can be displayed via :help quotes
#
# whose needs to be lowercase

use warnings;
use strict;

use constant SUCCESS => 255;

our $table = "quotes";
our %valid_quotes;

init();

sub init {
        my $q_sth = ${ utility::new_dbh_handle() } -> prepare(
		"select whose from $table group by whose"
	);
	$q_sth -> execute() or return;
	$valid_quotes{ $_->[0] } = 1 
			foreach ( @{ $q_sth->fetchall_arrayref() } );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	unless (defined keys %valid_quotes) {
		utility::spew($thischan, $thisuser, 
			"I'm sorry, $thisuser, I'm afraid there were no quotes in the database.");
		return;
	}
	foreach (":<quote key> -- show random quote",
			 "quotes I found in the database: ". join(", ", keys %valid_quotes) ) {
	        
		utility::spew($thischan, $thisuser, $_);
	}
}

sub quote {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless ($thismsg =~ /^:(\w+)$/ or $thismsg =~ /^(\w+)!/ );
	return unless defined $valid_quotes{ lc($1) };

	my $q_sth = ${ utility::new_dbh_handle() } -> prepare(
		"select quote, personal from $table 
		where whose = lower('$1') order by random() limit 1"
	);
	$q_sth -> execute() or return;
	my $quote = $q_sth -> fetchall_arrayref() -> [0];
	return unless (defined $quote && defined $quote->[0] && defined $quote->[1]);
        utility::spew( $thischan, $thisuser, $quote->[1] ? 
				"$thisuser, ".$quote -> [0]: "" . $quote -> [0] );
	return SUCCESS;
}

sub public {
	quote @_;
}

sub private {
	quote @_;
}

1;
