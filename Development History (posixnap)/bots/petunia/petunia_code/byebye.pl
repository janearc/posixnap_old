code
# exit at request of user.
sub byebye {
  return "byebye" if @_ == 0;
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless $thisuser =~ $maintainer;
  return unless $thismsg =~ /^:bye\s+$mynick/i;
  $nap -> disconnect();
  $dbh -> disconnect();
  exit 0;
}

(1 row)
