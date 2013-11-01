#
# ddate.pm
# returns the discordian date.
#

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
:ddate returns the discordian date.
HELP
}

# returns discordian date
sub public {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless $thismsg =~ /^:(dd|discordian)/;
  use Date::Discordian;
  my $disco = discordian(time());
  utility::spew( $thischan, $thisuser, "Today is $disco");
}

sub emote {
	()
}

sub private {
	()
}

1;
