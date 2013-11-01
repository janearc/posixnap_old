my @pongs = (
	"yes #thisuser?",
	"#thisuser?",
	"im busy right now #thisuser.",
	"what?!",
	"eh?",
);

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
ping simply returns a "yes i am here" to anyone wishing to query
whether the bot is still alive. example: petunia?
HELP
}

sub pong {
  my ($thischan, $thisuser, $thismsg) = (@_);
	my $mynick = $utility::config{nick};
  return unless $thismsg =~ /^$mynick\?/;
  my $pong = "";
  $pong = $pongs[ rand @pongs + 1 ] while $pong !~ /\w/;
	$pong =~ s/#thisuser/$thisuser/;
	utility::spew( $thischan, $thisuser, $pong );
}

sub public {
	pong(@_);
}

sub private {
	pong(@_);
}

1;
