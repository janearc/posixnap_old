our $help = "
No more often than every 5 minutes, this module compares each word
said to a database of Elvis Presley quotations.  It picks the word
uttered that is least common in Elvis's collected wisdom, and spews
a the least-recent quotation containing that word, if the frequency 
of that word is below a threshhold.
 
The intent is to spew random but vaguely appropriate Elvis quotes
into the conversation.
 
Also, if you say :quote, it will spew one completely random quote
from the database.  This also resets the timer.

:save_times will write the last-said info back into the database
";


my %quotes;
my %last;
my $last_spew = time;
my %frequency;
my %links;
my $thresh_freq;
my $thresh_time;
&load;

sub unload {
    &save_times();
}

sub public {
    my ($channel, $nick, $msg) = @_;
    
    &respond('public', $msg);
    if ($msg =~ m/elvis\s*,/i) { 
	&word_match('public',$msg, $thresh_freq); 
    }
}


sub private {
    my ($nick, $msg) = @_;

    &respond($nick, $msg, 1);
    if ($msg !~ /^\s*:/) { &word_match ($nick, $msg, 100); }
}

sub respond {
    my ($whom, $msg) = @_;
    if ($msg =~ /^\s*:save_times$/) { &save_times(); }
    if ($msg =~ m/^\s*:quote$/) {
	my @keys = keys %quotes;
	my $rand_idx = $keys[rand @keys];
	spew_quote($whom, $keys[rand @keys]);
	return 0;
    }

    if ($msg =~ /^\s*:save_times$/) { &save_times();  &utility::spew($whom, 'Wrote times to DB.');}
    if ($msg =~ /^\s*:timer now/) { $last_spew = now(); &utility::spew($whom, 'Timer set to now.');}
    if ($msg =~ /^\s*:timer epoch/) { $last_spew = 0; &utility::spew($whom, 'Timer set to the epoch.');}
}

sub word_match {
    my ($whom, $what, $thresh) = @_;
    my $best_word = undef;
    my $best_freq = 100000;
    while ($what =~ s/\b([\w\']+)\b//) {
	my $word = lc $1;
	if ((defined $frequency{$word})
	    && ($frequency{$word} < $best_freq)) {
	    $best_freq = $frequency{$word};
	    $best_word = $word;
	}
    }
    if ($best_freq < $thresh) {
	my @alinks = sort { $last{$a} <=> $last{$b} }
	                   @{$links{$best_word}};
	
	if (defined $alinks[0]) { &spew_quote($whom, $alinks[0]); }
    }
}

sub load {
    $thresh_freq = $config{'thresh_freq'};
    if (not defined $thresh_freq) { $thresh_freq = 5; }

    $thresh_time = $config{'thresh_time'};
    if (not defined $thresh_time) { $thresh_time = 300; }

    my $query = $dbh->selectall_arrayref("SELECT id, quote, date_part('epoch', last) FROM elvisquotes");
    my @rows = @$query;
    for my $row (@rows) {
	my ($idx, $quote, $last) = @$row;
	$quotes{$idx} = $quote;
	$last{$idx} = $last;

	# keep a list of all words in this quote in @words
	my @words;
	# for each word in the quote
	while ($quote =~ s/\b([\w\']+)\b//) {
	    my $word = $1;
	    # increment the frequency count for that word
	    $frequency{lc $word}++;
	    # if we haven't already done so,
	    if (not grep {m/$word/} @words) {
		# keep a shortcut to this quote
		push @{$links{lc $word}}, $idx;
		# and remember that we already saw this word in this quote
		push @words, $word;
	    }
	}
    }
    delete $frequency{'elvis'};
}

sub spew_quote {
    my ($whom, $idx) = @_;
    my $quote = $quotes{$idx};
    &utility::spew($whom, $quote);
    $last{$idx} = $last_spew = time;
    $dbh->do ('UPDATE elvisquotes SET last = now() WHERE id = ?', undef, $idx);
}

sub save_times {
    for my $idx (keys %quotes) {
	$dbh->do ('UPDATE elvisquotes SET last = timestamp(int4(?)) WHERE id = ?', undef, $last{$idx}, $idx);
    }
}
