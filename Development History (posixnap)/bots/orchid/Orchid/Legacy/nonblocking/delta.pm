#
# delta.pm
# return the bots "delta" -- that is the delta between time()
# and $epoch (time() when the bot arose)
#

sub public {
	delta( @_ );
}

sub emote {
	()
}

sub private {
	delta( @_ );
}

sub help {
  my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, ":uptime - returns the uptime of the bot." );
}

sub delta {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless $thismsg =~ /^:(uptime|delta)/;
  return if $thismsg =~ /\d/; # so as to not confuse echo

  # JZ: Yeah, I know, "don't fuck with the code". But I want to try oldschool.
  # JZ: After trying the oldschool (see commented portion below), I realised
  # JZ: what was wrong here. Bah!
  use Date::Calc qw{ Delta_YMDHMS };
  	my $epoch_start = $utility::config{epoch_start};
  my @epoch = (localtime($epoch_start))[5,4,3,2,1,0];
  my @delta = (localtime(time()))[5,4,3,2,1,0];
  $delta[0] += 1900; # heh! 19100!
  $epoch[0] += 1900;
  $delta[1] += 1; # date::calc elements start at 1 not 0.
  $epoch[1] += 1;
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

  # JZ: This was my new version. Works just as well I suppose, but I'll leave
  # JZ: good enough alone.
  #my $epoch = $utility::config{epoch_start};
  #my $now = time();

  #print "$epoch : $now\n";

  # JZ: why not a hash? because an array will preserve the order i want.
  #my @times = (
  #  $delta % 60 . 's',
  #  $delta / 60 % 60 . 'm',
  #  $delta / 60 / 60 % 24 . 'h',
  #  $delta / 60 / 60 / 24 % 365 . 'd',
  #);

  #foreach( @times ) {
  #  push @times, $_ if not /\d/;
  #  pop @times;	# pop the originals off, having pushed them on if nonzero
  #}
  
  #my $uptime = join ' ', reverse( @times );


  utility::spew( $thischan, $thisuser, $uptime );
}

1;
