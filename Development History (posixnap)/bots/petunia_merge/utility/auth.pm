package utility::auth;

use warnings;
use strict;

# pass us a hostmask followed by the user you want to test, and we'll see
# if they match. added for eventual use with auto-op

use utility;

sub _convert {
	my $irc_glob = shift;
	$irc_glob =~ s/\./\\./g;
	$irc_glob =~ s/\*/.*?/g;
	$irc_glob =~ s/\@/\\@/g;
	return $irc_glob;
}

sub test {
	my ($mask, $user) = (@_);
	$mask = _convert( $mask );
	if (lc($user) =~ lc($mask)) {
		return 1;
	}
	else {
		return 0;
	}
}

sub fqun_to_user {
	my ($fqun) = shift;
	my ($thisuser) = $fqun =~ /^([^!]+)!/;
	return $thisuser;
}

1;
