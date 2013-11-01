code
# karma decrementing
sub karma_decrement {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "karma_decrement" if @_ == 0;
  return 0 unless my ($item) = $thismsg =~ /((?:[\d\w_]+)|\([\w\s]+\))\-\-/;
  my $lookup = lc $item;
  my $dejavu = select_one("select count(value) from karma where item='$lookup'");
  if ($dejavu) {
    # they exist, we need to decrement them
    my $value = select_one("select value from karma where item='$lookup'");
    my $newvalue = $value - 1;
    $dbh -> do("update karma set value='$newvalue' where item='$lookup'");
    return 1;
  }
  else {
    # they do not exist, add them
    $dbh -> do("insert into karma(item, value) values('$lookup', '-1')");
    return 1;
  }
  return 0;
}

(1 row)
