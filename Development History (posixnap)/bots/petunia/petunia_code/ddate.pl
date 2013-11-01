code
# returns discordian date
sub ddate {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "discordian" if @_ == 0;
  return unless $thismsg =~ /^:(dd|discordian)/;
  use Date::Discordian;
  my $disco = discordian(time());
  $nap -> public_message("Today is $disco");
  return 1;
}

(1 row)
