code
# this is necessary for retort
sub bad_retort {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "bad_retort" if @_ == 0;
  return 0 unless $thismsg =~ /try again,? $mynick/;
  $nap -> public_message("roger, $thisuser [ not implemented ]");
  return 1;
}

(1 row)
