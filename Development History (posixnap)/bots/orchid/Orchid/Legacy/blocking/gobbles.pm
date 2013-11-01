#
# gobbles.pm
# return random gobbles text from their oh-so-funny advisories.
#

use warnings;
use strict;

my $gobble_dbh = ${ utility::new_dbh_handle() };

sub do_gobble {
	my ($thischan, $thisuser, $thismsg) = (@_);

	return unless $thismsg =~ /^:?gobbles?/;

	# we have to do this every time or we will run out of content.
	my $gobble_sth = $gobble_dbh -> prepare(qq{
		select content from gobbles_advisories order by random() limit 1 
	});
	$gobble_sth -> execute();

	# pull the content from the database.
	my ($content) = map { @{ $_ } } @{ $gobble_sth -> fetchall_arrayref() };
	# catch sentences (multiline) matching "GOBBLES ..."
	my @gobblings = $content =~ /[.!?;]+\s*(GOBBLES.*?[.!?;]+)/gsoi;
	my $thisgobble;
	if (not @gobblings or not $thisgobble = $gobblings[ int rand @gobblings + 1 ]) {
		# make sure the regex matched or say something "meaningful"
		$thisgobble = int rand 2 ? "hehehe GOBBLES" : "*GOBBLE*";
	}
	# lop off any newlines.
	$thisgobble =~ s[$/][ ]g;
	utility::spew( $thischan, $thisuser, $thisgobble );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
GOBBLES Labs feels that :gobbles is sufficient for use of the module.
HELP
}

sub public {
	do_gobble( @_ );
}

sub private {
	do_gobble( @_ );
}
