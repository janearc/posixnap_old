use warnings;
use strict;
use Time::localtime;
use Time::Timezone;
use Time::Local;

sub do_date {
	my ($thischan, $thisuser, $thismsg) = @_;
  return undef unless $thismsg =~ m/(?: ^:?newsdate )/xi;
  utility::spew( $thischan, $thisuser, "$thisuser, ".newsdate() );
}

sub newsdate{
	my @Months =	("Jan", "Feb", "Mar", "Apr", "May", "Jun",
			 "Jul", "Aug", "Sep", "Oct", "Nov", "Dev");
	my @Days =	("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
	my $now = time();
	my $then = timelocal(0,0,0,31,6,93);
	my $diff = ($now - $then)/(3600*24);
	my $pieces = localtime();
	return @Days[$pieces->wday]." ".@Months[$pieces->mon]." Sep ".
		(sprintf "%0.0f", $diff)." ".$pieces->hour.":".$pieces->min.":".$pieces->sec.
		" ".tz2zone()." 1993";
}

sub private {
	do_date(@_)
}

sub public {
	do_date(@_)
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, ":newsdate returns the current AOL haters' date on the bot's host." );
}
