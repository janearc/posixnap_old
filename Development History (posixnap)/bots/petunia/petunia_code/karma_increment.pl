code
sub karma_increment {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "karma_increment" if @_ == 0;
  return 0 unless my ($item) = $thismsg =~ /((?:\w+)|\([\w\s()]+\))\+\+/;
  my $lookup = lc $item;
	return 0 if $item eq "dxm";
  my $merge_checker = "select parent from merge where children like '\%##$lookup##\%'";
  my ($merged) = map { shift @{ $_ } } @{ $dbh -> selectall_arrayref($merge_checker) };

  # this is a straight lookup
  if (!$merged) {
    my $extant_checker = "select count(value) from karma where item=?";
    $extant_checker = $dbh -> prepare($extant_checker);
    $extant_checker -> execute($lookup);
    my ($extant) = map { @{ $_ } } @{ $extant_checker -> fetchall_arrayref() };

    if ($extant) {
      # we have a value in karma already, increment it
      my $value_puller = "select value from karma where item=?";
      $value_puller = $dbh -> prepare($value_puller);
      $value_puller -> execute($lookup);
      my ($value) = map { shift @{ $_ } } @{ $value_puller -> fetchall_arrayref() };

      my $value_updater = "update karma set value = ? where item = ?";
      $value_updater = $dbh -> prepare($value_updater);
      $value += $item eq $thisuser ? -1 : 1; # users cannot increment themselves
      $value_updater -> execute($value, $lookup);
      return 1;
    }
    # this is a new value
    else {
      my $value = $item eq $thisuser ? -1 : 1;
      my $inserter = "insert into karma (item, value) values (?, ?)";
      $inserter = $dbh -> prepare($inserter);
      $inserter -> execute($item, $value);
      return 1;
    }
  }
  # this is a merge lookup.
  else {
    # we have a value in karma already, increment it.. XXX: no merges for undef parents.
    my $value_puller = "select value from karma where item=?";
    $value_puller = $dbh -> prepare($value_puller);
    $value_puller -> execute($lookup);
    my ($value) = map { shift @{ $_ } } @{ $value_puller -> fetchall_arrayref() };

    my $value_updater = "update karma set value = ? where item = ?";
    $value_updater = $dbh -> prepare($value_updater);
    $value += $item eq $thisuser ? -1 : 1; # users cannot increment themselves
    $value_updater -> execute($value, $lookup);
    return 1;
  }
  return 0;
}

(1 row)
