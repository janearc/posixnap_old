code
sub echo {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "delta" if @_ == 0;
  return unless $thismsg =~ /^:(echo|delta)/;
  use Date::Calc qw{ Delta_YMDHMS };
  my ($to_check) = $thismsg =~ /^:(?:echo|delta)\s+(\d+)/;
  my @epoch = (localtime($to_check))[5,4,3,2,1,0];
  my @delta = (localtime(time()))[5,4,3,2,1,0];
  $delta[0] += 1900; # heh! 19100!
  $epoch[0] += 1900;
  # trickery!! 
  my @names = qw{ 0years 1months 2days 3hours 4minutes 5seconds };
  my %deltas = map { scalar shift @names => $_ } Delta_YMDHMS(@epoch, @delta);
  my $uptime = "";
  foreach my $time_element (sort keys %deltas) {
    if ($deltas{$time_element}) {
      $uptime .= "$deltas{$time_element} ";
      $time_element =~ y/[0-9]//d;
      $uptime .= "$time_element ";
    }
    else { next }
  }
	my $grok_server = $dbh -> prepare(qq{
		select server from config where server is not null limit 1
	});
	$grok_server -> execute();
	my ($server) = map { @{ $_ } } @{ $grok_server -> fetchall_arrayref() };
  $uptime = "You appear to be $uptime"."away from $server";
  if ($uptime eq "You appear to be away from $server") {
    $uptime = "You are in realtime sync with $server."
  }
  $nap -> public_message( "$thisuser, $uptime" );
  return 1;
}

(1 row)
