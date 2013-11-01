our $help ='
":channel foo" directs Elvis to go hang out in the #foo channel.';


sub public {
    my ($channel, $nick, $msg) = @_;
    &private ($nick, $msg);
}

sub private {
    my ($nick, $msg) = @_;
    if ($msg =~ m/^\s*:channel\s+(\S+)/) {
	my $newchannel = $1;
	$nap->part_channel($nap->channel);
	$nap->join_channel($newchannel);
    }
}


1;
