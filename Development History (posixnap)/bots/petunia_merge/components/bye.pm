use warnings;
use strict;
use Carp qw{ confess };

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "not a chance." );
}

sub private {
	my ($thischan, $thisuser, $thismsg) = (@_);
	if ($thismsg eq 'AUTH: bye' and not $thischan) {
		utility::debug( "user $thisuser requested bailout...\n" );
		confess "user $thisuser requested bailout";
		exit 255; # !!!
	}
}

