code
# just a straight lookup.
sub karma_lookup {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "karma_lookup" if @_ == 0;
  return 0 unless $thismsg =~ /^:karma/i;
  my ($item) = $thismsg =~ /^:karma\s+((?:[\d\w_]+)|\([\w\s]+\))/;
  my $lookup = lc $item;
  my $dejavu = select_one("select count(value) from karma where item='$lookup'");
  if ($dejavu) {
    return 0 if $item =~ /^\s+/;
    return 0 if !$item;
    my $karma = select_one("select sum(value) from karma where item='$lookup'");
    $nap -> public_message("$item has $karma karma");
    return 1;
  }
  else {
    return 0 if $item =~ /^\s+/;
    $nap -> public_message("$item has neutral karma");
    return 1;
  }
  return 0;
}

(1 row)
