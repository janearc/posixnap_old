code
sub delta {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "delta" if @_ == 0;
  return unless $thismsg =~ /^:(uptime|delta)/;
        return if $thismsg =~ /\d/; # so as to not confuse echo
  use Date::Calc qw{ Delta_YMDHMS };
  my @epoch = (localtime($epoch_start))[5,4,3,2,1,0];
  my @delta = (localtime(time()))[5,4,3,2,1,0];
  use Data::Dumper; print Dumper \@epoch; print Dumper \@delta;
  $delta[0] += 1900; # heh! 19100!
  $epoch[0] += 1900;
  $delta[1] += 1; # date::calc elements start at 1 not 0.
  $epoch[1] += 1;
  use Data::Dumper; print Dumper \@epoch; print Dumper \@delta;
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
  $nap -> public_message( $uptime );
  return 1;
}

(1 row)
