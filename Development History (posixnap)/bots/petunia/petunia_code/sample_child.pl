code
sub sample_child {
  my $command_string = qr{^buh};
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "sample_child" if @_ == 0;
  return undef unless $thismsg =~ $command_string;
  $nap -> public_message("$thisuser, go fuck your buh'ing self, mmmkay");
  return 1;
}

(1 row)
