sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
  	my $command_string = qr{^:wizard};
  	return undef unless $thismsg =~ $command_string;
  	#utility::spew( $thischan, $thisuser, "$thisuser, go fuck your buh'ing self, mmmkay" );
	my @responses = ( 'The Signs Point To Yes..',
			  'Yes..',
			  'You May Rely On It..',
			  'Ask Again Later..',
			  'Cocentrate and Ask Again..',
			  'Outlook is Good..',
			  'My Sources Say No..',
			  'Better Not Tell You Now..',
			  'Without a Doubt..',
			  'The Spirits are Hazy..',
			  'It Is Decidedly so..',
			  'I Cannot Predict That Now..',
			  'The Spirits Say No..',
			  'As I See It, Yes..',
			  'It Is Certain..',
			  'Yes, Definately..',
			  'Don\'t Count on It..',
			  'Most Likely..',
			  'Outlook Not So Good..');
	my $return = $responses[int(rand()*scalar(@responses))];
	utility::spew( $thischan, $thisuser, qq{I have consulted the wizard and he has said:});
	utility::spew( $thischan, $thisuser, qq{   } . $return );
			 
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
:wizard <question> Will cause me to consult the wizard with an answer to your question. Please ask yes or no only kthx.
HELP
}

1;
