code
# stupid wrapper around bone::easy
sub bone {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "bone" if @_ == 0;
  return unless $thismsg =~ /^:bone /;
  my ($unwitting_victim) = $thismsg =~ /^:bone\s+([\s\S]+)/;
  return 0 unless $unwitting_victim and $unwitting_victim !~ /^\s/;
  use Bone::Easy;
  my $phrase = pickup;
  $nap -> public_message($phrase);
}

(1 row)
