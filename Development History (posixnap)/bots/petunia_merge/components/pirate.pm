use Acme::Scurvy::Whoreson::BilgeRat;

my $generator = Acme::Scurvy::Whoreson::BilgeRat -> new ( language => 'pirate' );

sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
  return undef unless $thismsg =~ /^:(?:bea)?pirate/;
  utility::spew( $thischan, $thisuser, "Ye $generator!" ); # odd api
}

sub emote {
	()
}

sub private {
	()
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser,  "Yarrrr!! Ye be needing no help matey!!!!" );
}

1;
