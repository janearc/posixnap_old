sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
 	 my $command_string = qr{^:rsp};
  	return undef unless $thismsg =~ $command_string;
	$thismsg =~ s/^:rsp\s+//;
	unless ($thismsg =~ /rock|paper|scissor/) {  return; }
	my $computer;
	
	my %winnar = ( 'rock' => 'scissor',
		       'paper' => 'rock',
		       'scissor' => 'paper');

	my @keys = keys %winnar;
	$computer = $keys[int(rand()*3)];
	if ($computer =~ /$thismsg/) { 
		utility::spew($thischan, $thisuser, "$thisuser: TIE! $thismsg = $computer");
		return;
	}

	unless ($winnar{$computer} =~ /$thismsg/) { 
		utility::spew($thischan, $thisuser, "$thisuser: WINNER! $thismsg > $computer")
	}
	else {
		utility::spew($thischan, $thisuser, "$thisuser: LOSER! $computer > $thismsg")
	}
 
	
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
uh.. rock scissor paper
:rsp (rock|paper|scissor)
HELP
}

1;
