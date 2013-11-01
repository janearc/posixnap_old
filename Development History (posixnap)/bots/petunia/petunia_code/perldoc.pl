code
sub perldoc {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "perldoc" if @_ == 0;
  return unless $thismsg =~ /^perldoc /;
  my ($query) = $thismsg =~ /^perldoc (.*)/;
  my $result;
  if (($result) = map { shift @{ $_ } } @{ $dbh -> selectall_arrayref("select description from perldoc_fact where factlet = '$query'") }) {
    $nap -> public_message($result);
    return 1;
  }
  elsif (($result) = map { shift @{ $_ } } @{ $dbh -> selectall_arrayref("select description from perldoc_functions where func = '$query'") }) {
    $nap -> public_message($result);
  }
  elsif (($result) = map { shift @{ $_ } } @{ $dbh -> selectall_arrayref("select description from perldoc_modules where module = '$query'") }) {
    $nap -> public_message($result);
  }
  else {
    $nap -> public_message("sorry, $thisuser, nothing found.");
    return 0;
  }
  return 0;
}

(1 row)
