code
sub ping {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "ping" if @_ == 0;
  return unless $thismsg =~ /^$mynick\?/;
  my @pongs = (
    "yes $thisuser?",
    "$thisuser?",
    "im busy right now $thisuser.",
    "what?!",
    "eh?",
  );
  my $pong = "";
  $pong = $pongs[ rand @pongs + 1 ] while $pong !~ /\w/;
  $nap -> public_message( $pong );
  return 1;
}

(1 row)
