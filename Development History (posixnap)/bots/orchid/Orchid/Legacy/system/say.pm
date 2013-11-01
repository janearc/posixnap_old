use warnings;
use strict;

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "say is not intended for non-maintainer users." );
}

sub send_public {
	my ($thisuser, $thischan, $thismsg ) = (@_);
	utility::spew( $thischan, $thisuser, $thismsg );
}

sub private {
	send_public( $_[0], ( $_[2] =~ /^AUTH: say (#\S+) (.*)/ ? ($1, $2) : return undef) );
}

