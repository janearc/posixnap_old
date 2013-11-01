sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
  my $command_string = qr{^buh};
  return undef unless $thismsg =~ $command_string;
  utility::spew( $thischan, $thisuser, "$thisuser, go fuck your buh'ing self, mmmkay" );
}

sub emote {
	()
}

sub private {
	()
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
sample_child is not intended to do anything at all. it is an example of petunia's API.
HELP
}

1;
