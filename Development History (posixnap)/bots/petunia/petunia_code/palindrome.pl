code
# reverse stuff for a user. for narse. bleh.
sub palindrome {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "palindrome" if @_ == 0;
  return unless $thismsg =~ /^:(?:reverse|pd|palindrome) /;
  my ($this_msg) = $thismsg =~ /^:(?:reverse|pd|palindrome)\s+(.*)/;
  $this_msg = reverse($this_msg);
  $this_msg =~ y{:\\+/}{}d;
  return 0 unless $this_msg =~ /[^\s]/;
  $nap -> public_message( reverse($this_msg) );
  return 1;
}

(1 row)
