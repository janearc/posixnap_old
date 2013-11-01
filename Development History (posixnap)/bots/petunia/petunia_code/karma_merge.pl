code
sub karma_merge {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return 0 unless $thisuser =~ $maintainer;
  return "karma_merge" if @_ == 0;
  return unless $thismsg =~ /^:merge /;
  my ($parent, $child) = $thismsg =~ /:merge ([^\s()]+) (.+)/;
  my $sth = "select count(item) from karma where item = ?";
  $sth = $dbh -> prepare($sth);
  $sth -> execute($parent);
  my ($dejavu) = map { @{ $_ } } @{ $sth -> fetchall_arrayref };
  if ($dejavu) {
    # we have seen the parent.
    $sth -> execute($child);
    ($dejavu) = map { @{ $_ } } @{ $sth -> fetchall_arrayref };

    if ($dejavu) {
      # we have also seen the child.
      my $checker = "select value from karma where item = ?";
      $checker = $dbh -> prepare($checker);
      $checker -> execute($parent);
      my ($par_val) = map { shift @{ $_ } } @{ $checker -> fetchall_arrayref };
      $checker -> execute($child);
      my ($chl_val) = map { shift @{ $_ } } @{ $checker -> fetchall_arrayref };
      my $new_val = $par_val + $chl_val;
      my $updater = "update karma set value = '$new_val' where item = '$parent'";
      warn "parent -> $par_val child -> $chl_val new -> $new_val\n";
      $dbh -> do($updater);
      my $deleter = "delete from karma where item = ?";

      #--
      $deleter = $dbh -> prepare($deleter);
      $deleter -> execute($child);

      #--
      $checker = "select children from merge where parent = ? ";
      $checker = $dbh -> prepare($checker);
      $checker -> execute($checker);

      ($dejavu) = map { shift @{ $_ } } @{ $checker -> fetchall_arrayref };
      if ($dejavu) {
        # we have seen this merge before, concatenate it.
        $updater = "update merger set children = ? where parent = ?";
        my $concatenator = "select children from merge where parent = ?";
        $concatenator = $dbh -> prepare($concatenator);
        ($concatenator) = map { shift @{ $_ } } @{ $concatenator -> fetchall_arrayref };
        my $new_child = "$concatenator##$child##";
        $updater -> update($new_child, $parent);
      }
      else {
        # we have not got a merge value
        $deleter -> execute($child);
        my $merger = "insert into merge (parent, children) values ?, ?";
        $merger = $dbh -> prepare($merger);
        $merger -> execute($parent, $child);
      }
      # yay, successful.
      $nap -> public_message( "karma merged $parent ($child)" );
      return 1;
    }
    else {
      # we havent seen the child.
      $nap -> public_message( "no karma item found for $child, try using :karma..." );
      return 0;
    }
  }
  else {
    # we havent seen the parent.
    $nap -> public_message( "no karma item found for $child, try using :karma..." );
    return 0;
  }
  return 0;
}

(1 row)
