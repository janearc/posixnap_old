use warnings;
use strict;
use Sys::Load qw{ getload };

# respond with the number of userseconds we've consumed.
sub pig {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless $thismsg eq ':pig';
  use BSD::Resource;
  my           ($usertime, $systemtime,
                $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
                $inblock, $oublock, $msgsnd, $msgrcv,
                $nsignals, $nvcsw, $nivcsw) = getrusage();
  utility::spew( $thischan, $thisuser, "$usertime userseconds consumed thus far ( sysload: ".
		(join ", ", getload())." )" );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, ":pig returns the time in userseconds the bot has consumed on the host's cpu." );
}

sub public {
	pig( @_ );
}

sub private {
	pig( @_ );
}
