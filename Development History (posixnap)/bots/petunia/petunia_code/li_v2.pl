code
# lineitemveto($definition);
# lineitemveto($definition, "private", $nick);
# modified from utilibot. essentially intact.
sub li_v2 {
	return 0 if $_[0] =~ /^#/;
	my $rowcount = 1;
	my ($toobig, $private, $thisnick) = (@_);
	use Text::Wrap qw{ wrap };
	$Text::Wrap::columns = 75;
	my $infobot_action_items = join "|", qw{
		<action> <reply> $who \|
	};
	if ($toobig =~ $infobot_action_items) {
		parse_infobot_action_items($toobig, $thisnick);
		return 0;
	}
	if ((wrap($toobig)) > 4) {
		$nap -> public_message("truncating...");
		$nap -> public_message($_) for (wrap($toobig))[0 .. 3];
		return 1;
	}
	else {
		$nap -> public_message($_) for wrap($toobig);
		return 1;
	}
	return 0;
}

(1 row)
