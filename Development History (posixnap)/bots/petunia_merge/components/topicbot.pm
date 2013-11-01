sub topic {
	my ($thischan, $thisuser, $thistopic, $kernel) = (@_);
  return ;
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
don't be an idiot. this is not an interactive module.
HELP
}

1;
