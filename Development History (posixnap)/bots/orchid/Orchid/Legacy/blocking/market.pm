##
## market.pm
##
## initiate stock market trades (against postgres) via a chat-driven
## interface. common libraries here, rather than separate modules.
##

use warnings;
use strict;

use Finance::Quote;
use POE;

use constant CASHFLOW => 1;
use constant PERMISSION_DENIED => 2;
use constant NOSUCH_STOCK => 3;
use constant INSUFFICIENT_FUNDS => 4;
use constant UNSPECIFIED_ERROR => 5;
use constant NOSUCH_PLAYER => 6;
use constant INSUFFICIENT_SHARES => 7;

use constant SUCCESS => 255;

use constant COMMISSION => 9.99;

our %CONFIG;
our @DSN;

our $mkt_dbh;
our $mkt_query = Finance::Quote -> new( );

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my ($query) = $thismsg =~ /^:help\s+market\s+(\S+)/;

	my %help = (
		'ml' => 
			":ml <username> - returns the user's net worth including cash and stock positions.",
		'last' => 
			":last <symbol> - returns the last traded price, bid price, and asking price of a symbol.".
			"Can look up mutual funds as well.",
		'holdings' => 
			":holdings <no arguments> - returns a list of your positions to you, privately.",
		'buy' => 
			":buy <count> <symbol> - e.g., :buy 500 AAPL. buys <count> number of shares in ".
			"<symbol>, but only if you have enough dinero.",
		'sell' => 
			":sell <count> <symbol> - e.g., :sell 500 MSFT. sells <count> number of shares in ".
			"<symbol>, and gives you an appropriate amount of cash in return.",
	);
	
	if (not defined $query and not $help{$query}) {
		utility::spew( $thischan, $thisuser, 
			"market is a very complex module. please ask for ':help market [topic]'".
			" where topic is one of 'last', 'sell', 'buy', 'holdings' or 'ml'"
		);
		return SUCCESS;
	}
	else {
		utility::spew( $thischan, $thisuser, $help{$query} );
		return SUCCESS;
	}
}
		
# init, this initializes the stuff we need to do on a continual basis
sub init {
	my ($kernel) = shift;
	my ($dsn, $config) = (@_);
	@DSN = @{ $dsn };
	%CONFIG = %{ $config };
	$mkt_dbh = init_dbh();
	POE::Session -> new(
		_start => sub { market_maint( @_ ); utility::debug( "booting market maintenance stuff" ) },
		_stop => sub { utility::debug( "oh dear, market's session stopped." ) },
		market_maint => \&market_maint,
	);
}

# we're doing everything locally because of asynchronous IO
sub init_dbh {
	die "\@DSN not populated\n" unless defined @DSN;
	my $dbh = DBI -> connect( @DSN )
		or die DBI -> errstr();
	return $dbh;
}

sub market_maint {
	$mkt_dbh -> do(qq{
		delete from stocks where shares = 0;
	});
	$_[KERNEL] -> delay( market_maint => 120 ); # delay two minutes
}

# executes a trade to purchase a stock.
sub market_buy {
	my ($thischan, $thisuser, $thismsg, $shares_bought, $stock_bought) = @_;

	if (($shares_bought =~ /\D/) or ($stock_bought =~ /[^A-Z]/)) {
		utility::debug( "malformed parameters." );
		return UNSPECIFIED_ERROR;
	}

	my $cash = lookup_cash( $thisuser );
	my $cost = fq_ask( $stock_bought ) || fq_last( $stock_bought );
	warn "cost: $cost\n";
	my $gross = $cost * $shares_bought;

	unless ($cost) {
		utility::spew( $thischan, $thisuser, "oops, no such symbol $stock_bought" );
		return NOSUCH_STOCK;
	}

	my $comm_factor = int ($shares_bought / 1000);
	my $commission = $comm_factor > 1 ? $comm_factor * COMMISSION : COMMISSION;

	if ($gross + $commission > $cash) {
		utility::spew( $thischan, $thisuser, "$thisuser, you do not have enough capital." );
		return INSUFFICIENT_FUNDS;
	}

	my $price_A = lookup_position( $thisuser, $stock_bought ) -> {price};
	my $quantity_A = lookup_position( $thisuser, $stock_bought ) -> {quantity};

	# price_A and quantity_A are the extant positions in the database, whereas
	# the _B items are the "new" position.

	if (( defined $price_A ) and ( defined $quantity_A )) {
		# user owns the stock, calculate new price, record it, notify user.
		my $total_quantity = $quantity_A + $shares_bought;
		my $quantity_B = $shares_bought;
		my $price_B = $cost;
		my $new_price = ($quantity_A / $total_quantity * $price_A) + ($quantity_B / $total_quantity * $price_B);

		my $sth = $mkt_dbh -> prepare(qq{
			update stocks set shares = ?, initial_price = ?
				where upper(player) = upper(?) and stock = ?
		});
		$sth -> execute($total_quantity, $new_price, $thisuser, $stock_bought);
		utility::private_spew( $thischan, $thisuser, sprintf("$quantity_B shares of $stock_bought [ \@ \$%.2f ] added [ new price: \$%.2f ]",$price_B,$new_price) );
	}
	else {
		# user does not own the stock. purchase at current price.
		my $sth = $mkt_dbh -> prepare(qq{
			insert into stocks (player, stock, initial_price, shares)
				values (?, ?, ?, ?)
		});
		$sth -> execute($thisuser, $stock_bought, $cost, $shares_bought);
		utility::private_spew( $thischan, $thisuser, sprintf("ok, $thisuser, you just spent \$%.2f on $shares_bought shares of %s",$gross,fq_name( $stock_bought ) ) );
	}
	$cash -= $gross;
	my $sth = $mkt_dbh -> prepare(qq{
		update profits set profit = ? where who = ?
	});
	$sth -> execute($cash, $thisuser);
	utility::private_spew( $thischan, $thisuser, "\$$commission in commission deducted" );
	utility::private_spew( $thischan, $thisuser, sprintf("\$%.2f left, $thisuser",$cash) );
	feed_petunia( $commission );
	return SUCCESS;
}

# return a listing of the user's portfolio to them.
sub market_holdings {
	my ($thischan, $thisuser, $thismsg) = (@_);

	unless (is_playing( $thisuser )) {
		utility::spew($thischan, $thisuser, "try again, $thisuser... or do :minit yes if youd like to start playing" );
		return SUCCESS;
	}
	my $fetcher = $mkt_dbh -> prepare(qq{
		select player, stock, initial_price, shares 
			from stocks where upper(player) = upper(?) order by initial_price * shares
	});
	$fetcher -> execute( $thisuser );
	my @positions = @{ $fetcher -> fetchall_arrayref() };
	my $profits = lookup_cash( $thisuser );
	utility::private_notice($thischan, $thisuser,  sprintf("You've got \$%.2f, $thisuser",$profits) );

	# iterate over their portfolio
	foreach my $position (@positions) {
		my ($player, $stock, $initial_price, $shares) = @{ $position };
		return 0 unless ($player && $stock && defined $initial_price && defined $shares);
		my $new_cost = fq_last( $stock );
		my $net_value = $new_cost * $shares;
		utility::private_notice( 
			$thischan, $thisuser,  
			sprintf "%5s -> %6d @ %6.2f [ now: %6.2f ] [ value: %9.2f ]", 
				$stock, $shares, $initial_price, $new_cost, $net_value
		);
	}
	return SUCCESS;
}

# initialize a user into the market.
sub market_init {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my $sth;
	$sth = $mkt_dbh -> prepare(qq{
		delete from stocks where upper(player) = upper(?);
		delete from market_players where upper(player) = upper(?);
		delete from profits where upper(who) = upper(?);
		insert into market_players (player) values (?);
		insert into profits (who, profit) values (?, ?);
	});
	$sth -> execute($thisuser, $thisuser, $thisuser, $thisuser, $thisuser, 10000);
	utility::spew( $thischan, $thisuser, "welcome to the stock market, $thisuser, you've got \$10,000!" );
	return SUCCESS;
}

# return a user's status (portfolio value, capital available)
# for another user.
sub market_lookup {
	my ($thischan, $thisuser, $thismsg, $lookup) = (@_);

	return NOSUCH_PLAYER unless is_playing( $lookup );

	# get their capital available
	my $cash = lookup_cash($lookup);
	
	# pick out their portfolio
	my $sth = $mkt_dbh -> prepare(qq{
		select * from stocks where upper(player) = upper(?)
	});
	$sth -> execute($lookup);

	my (@positions) = @{ $sth -> fetchall_arrayref({}) };
	if (@positions) {
		return NOSUCH_PLAYER unless @positions;
		
		my $profit = 0; my $market_value;
	
		# determine actual value of portfolio
		foreach my $position (@positions) {
			my $bought_cost = $position -> {initial_price};
			my $stock = $position -> {stock};
			my $new_cost = fq_last( $stock ) * $position -> {shares};
			my $old_cost = $position -> {initial_price} * $position -> {shares};
			$market_value += $new_cost;
			$profit += ($new_cost - $old_cost);
		}
	
		# determine cost of the portfolio
		my $summer = $mkt_dbh -> prepare(qq{
			select sum(shares * initial_price) from stocks where upper(player) = upper(?)
		});
		$summer -> execute($lookup);
		my ($sum) = map { @{ $_ } } @{ $summer -> fetchall_arrayref() };
	
		my $mode = ($market_value - $sum) > 0 ? "made" : "lost";
		my $mode_p = ($market_value - $sum) > 0 ? "gained" : "lost";
					
		my $diff = ($market_value - $sum) > 0? ($market_value - $sum) : ($sum - $market_value);
	
		my $pct = $sum == 0 ? 0 : sprintf("%5.2f",$diff / ($sum / 100));
	
		utility::spew( $thischan, $thisuser, sprintf("$lookup has \$%0.2f in assets, for which \$%0.2f was paid (\%$pct $mode_p)",$market_value,$sum) );
		utility::spew( $thischan, $thisuser, sprintf("$lookup also has \$%0.2f in cash, or a net worth of \$%0.2f.",$cash, $cash + $market_value) );
	}
	else {
		utility::spew( $thischan, $thisuser, sprintf("$lookup has \$%.2f in cash and no positions.",$cash) );
	}
}

# initiate a sell of a stock
sub market_sell {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my ($shares_sold, $stock_sold) = $thismsg =~ /^:sell\s+(\d+)\s+(\S+)/;

	# yahoo requires uc.
	$stock_sold = uc $stock_sold;

	my $comm_factor = int ($shares_sold / 1000);
	my $commission = $comm_factor > 1 ? $comm_factor * COMMISSION : COMMISSION;

	my $position = lookup_position( $thisuser, $stock_sold );
	return INSUFFICIENT_SHARES if $position -> {quantity} < $shares_sold;

	my $sum = ( fq_bid( $stock_sold ) || fq_last( $stock_sold ) ) * $shares_sold;

	$sum -= $commission;

	# update their cash and shares
	my $profitizer = $mkt_dbh -> prepare(qq{
		update profits set profit = profit + ? where who = ? 
	});
	my $reducer = $mkt_dbh -> prepare(qq{
		update stocks set shares = ? where player = ? and stock = ?
	});
	$profitizer -> execute($sum, $thisuser);
	$reducer -> execute(($position -> {quantity} - $shares_sold), $thisuser, $stock_sold);

	# let them know it was ok
	utility::private_spew( $thischan, $thisuser, "\$$sum ". (($sum > 0) ? "added to" : "subtracted from ") ." your pile of cash $thisuser" );
	utility::private_spew( $thischan, $thisuser, "\$$commission deducted." );
	feed_petunia( $commission );
	return SUCCESS;
}

# lookup the last price, the bid price, and the ask price.
sub market_last {
	my ($thischan, $thisuser, $thismsg) = (@_);
	my ($query) = $thismsg =~ /^:last\s+(\S+)/;
	return unless $query;

	if (my $err = fq_valid( $query )) {
		utility::spew( $thischan, $thisuser, $err );
		return SUCCESS;
	}

	# get our quote information
	my $name = fq_name( $query );
	my $last = fq_last( $query );
	my $bid  = fq_bid( $query ) || fq_last( $query );
	my $ask  = fq_ask( $query ) || fq_last( $query );

	# usually names less than 4 chars are abbreviations, so we uc those
	# else we treat them like words.
	if (length $name > 4 and $name =~ /\S+/) {
		$name = ucfirst_words( $name );
	}
	else {
		$name = uc $name;
	}

	# some stocks arent particularly volatile and thus their bid price 
	# and asking prices are the last traded price. CM for example.
	if (not $bid) {
		$bid = $last;
	}
	if (not $ask) {
		$ask = $last;
	}

	utility::spew( $thischan, $thisuser, 
		"$name last traded at $last [ Bid: $bid | Ask: $ask ]"
	);
	return SUCCESS;
}

#
# utility subroutines
#

# we like our commission
sub feed_petunia {
	my $commission = shift;
	my $comm_sth = $mkt_dbh -> prepare(qq{
		update profits set profit = profit + ? where upper(who) = upper('petunia');
	});
	$comm_sth -> execute($commission);
}

# return a true or false value representing whether somebody is actively
# participating in the market_* hierarchy.
sub is_playing {
	my $target = shift;
	my $sth = $mkt_dbh -> prepare(qq{
		select count(who) from profits where upper(who) = upper(?)
	});
	$sth -> execute( $target );
	return ( map { @{ $_ } } @{ $sth -> fetchall_arrayref() } )[0] or undef;
}

# return whether there was an error fetching a quote on the item
# return 0 silently if its successful, or return the error message 
# if there was one.
sub fq_valid {
	my $target = shift;
	if ($mkt_query -> yahoo( uc $target ) -> { uc $target, "success" }) {
		return $mkt_query -> yahoo( uc $target ) -> { uc $target, "errormsg" };
	}
	else {
		return 0;
	}
}

# return the last quote from the yahoo object
sub fq_last {
	my $target = shift;
	return $mkt_query -> yahoo( uc $target ) -> { uc $target, "last" } or undef;
}

# return the yahoo name for a given symbol.
sub fq_name {
	my $target = shift;
	return ucfirst_words( $mkt_query -> yahoo( uc $target ) -> { uc $target, "name" } )or undef;
}

# return the bid price for a given symbol.
sub fq_bid {
	my $target = shift;
	return ucfirst_words( $mkt_query -> yahoo( uc $target ) -> { uc $target, "bid" } )or undef;
}

# return the asking price for a given symbol.
sub fq_ask {
	my $target = shift;
	return ucfirst_words( $mkt_query -> yahoo( uc $target ) -> { uc $target, "ask" } )or undef;
}

# lookup_cash
# returns a scalar containing the users available liquid worth,
# or undef if they are no intialized.
sub lookup_cash {
	my $user = shift;
	my $cashpuller = $mkt_dbh -> prepare(qq{
		select profit from profits where upper(who) = upper(?)
	});
	$cashpuller -> execute($user);
	my ($cash) = map { @{ $_ } } @{ $cashpuller -> fetchall_arrayref() };
	return $cash or undef;
}

# lookup_position
# returns a position for a user. the position is represented as the
# number of shares, and the price paid for said shares. this is
# represented as an average in the database rather than specific
# positions. data is returned in a hashref, or undef if user does
# not own any shares of requested equity.
sub lookup_position {
	my ($user, $symbol) = @_;

	my $present_sth = $mkt_dbh -> prepare(qq{
		select count(player) from stocks where stock = ?
			and upper(player) = upper(?)
	});
	$present_sth -> execute($symbol, $user);
	my ($present) = map { @{ $_ } } @{ $present_sth -> fetchall_arrayref() };

	if ($present) {
		# user owns this stock
		my $sth;
		$sth = $mkt_dbh -> prepare(qq{
			select initial_price, shares from stocks
				where upper(player) = upper(?) and stock = ?
		});
		$sth -> execute($user, $symbol);
		my ($price, $quantity) = @{ $sth -> fetchall_arrayref() -> [0] };
		return { price => $price, quantity => $quantity };
	}
	else {
		# user does not own this stock
		return { };
	}
	return undef;
}

sub parse {
	my ($thischan, $thisuser, $thismsg) = (@_);
	# rework this if you like. its kind of hackish.
	if (my ($shares_bought, $stock_bought) = $thismsg =~ /^:buy\s+(\d+)\s+(\S+)/) {
		my $result = market_buy( $thischan, $thisuser, $thismsg, $shares_bought, uc $stock_bought );
	}
	elsif (my ($shares_sold, $stock_sold) = $thismsg =~ /^:sell\s+(\d+)\s+(\S+)/) {
		my $result = market_sell( $thischan, $thisuser, $thismsg, $shares_sold, uc $stock_sold );
	}
	elsif ($thismsg =~ /^:holdings/) {
		my $result = market_holdings( $thischan, $thisuser, $thismsg );
	}
	elsif ($thismsg =~ /^:minit yes/) {
		my $result = market_init( $thischan, $thisuser, $thismsg );
	}
	elsif ($thismsg =~ /^:last\s+(\S+)/) {
		my $result = market_last( $thischan, $thisuser, $thismsg );
	}
	elsif ($thismsg =~ /^:ml\s+(\S+)/) {
		my $result = market_lookup( $thischan, $thisuser, $thismsg, $1 );
	}
}

sub ucfirst_words {
	my $in = shift;
	return join " ", map ucfirst(lc $_), (split /\s+/, $in);
}

sub public {
	parse( @_ );
}

sub private { 
	parse( @_ );
}

1;
