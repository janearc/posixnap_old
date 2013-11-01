code
#stupid wrapper around text::bastardize and bone easy. ugh.
sub kewl_bastardize {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "kewl_bastardize" if @_ == 0;
  return unless $thismsg =~ /^:kb/;
  my ($bidding) = $thismsg =~ m/^:kb (.*)/;
  use Text::Bastardize;
  if ($bidding) {
    my $to_b = $bidding;
    my $k = new Text::Bastardize;
    $k -> charge($to_b);
    my ($barf) = ($k -> k3wlt0k)[0];
    $nap -> public_message($barf);
    return 1;
  }
  else {
    use Bone::Easy;
    my $to_b = pickup;
    my $k = new Text::Bastardize;
    $k -> charge($to_b);
    my $barf = ($k -> k3wlt0k)[0];
    $nap -> public_message($barf);
    return 1;
  }
  return 0;
}

(1 row)
