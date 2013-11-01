sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, ':kb or :kb [ text to bastardize ]' );
	utility::spew( $thischan, $thisuser, 'instead of "kb" you may also specify your favourite Text::Bastardize method' );
	utility::spew( $thischan, $thisuser, 'are you *sure* you want to use this module?' );
}

sub private {
	kewl_bastardize(@_);
}

sub public {
	kewl_bastardize(@_);
}

sub kewl_bastardize {

  my ($thischan, $thisuser, $thismsg) = (@_);
  
  return unless (my ($cmd, $bidding) = 
	 $thismsg =~ m/^:(kb|rot13|k3wlt0k|rdct|ppig|rev|censor|n20e)\s*(.*)/);
  
  use Text::Bastardize;

  if (! $bidding) {
    use Bone::Easy;
    $bidding = pickup;
  }
  
  my $k = new Text::Bastardize;
  $k -> charge($bidding);
  
  $cmd =~ s/ppig/pig/;
  
  my $barf = ($cmd eq "kb") ? ($k -> k3wlt0k)[0] : ($k -> $cmd)[0];
  utility::spew($thischan, $thisuser, $barf);
  return 0;
}
