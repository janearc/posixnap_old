use POSIX;
use Safe;
use Broker::NVStorage;	# nonvolatile storage, hurrah
use strict;
no strict qw{ refs };
use warnings;
our ($lastre_time, %recent_re);

our $store = Broker::NVStorage -> new();
# JZ: don't do this dumbass.
#our %last = map { $_ => $store->nv_retrieve($_) } @{ $store->nv_records() };

our $testmsg = "";
our $compartment = new Safe;
$compartment->permit(':default');
$compartment->share('$testmsg');

$lastre_time = 0; # explicit initialisation to avoid complaints


sub do_parse {
    my ($thischan, $thisuser, $thismsg) = @_;
    my ($saferes);

    # cleanse it of control characters
    $thismsg =~ s/[[:cntrl:]]//g;

    # christ this looks ugly. that's why i like it :)
    my $arrayref = $store->nv_retrieve( $thisuser );
    my @last = $$arrayref ? @$$arrayref : ();	# message list

    ## This is the hairy regexp that matches the patterns
    # JZ: added sc flags for (y|tr)///, and m//.
    # JZ: also added the delimiter to the $pat no-match
    if (scalar @last and my ($op, $delimiter, $pat, undef, $repl, undef,
	    $slashflags, $flags) = 

	$thismsg =~ m%
	^\s*                         # optional leading whitespace
	(s|tr|y|m)                   # the operation
	([/!|:;-])                   # the delimiter
	(([^\$\\\2]|\\.)*?\$?)       # the pattern: (anything but '\' or '$' or
				     # the delimiter), or '\.', non-greedy.
				     # '$' is okay at the end.
	(?(?{$1 ne 'm'})	     # fancy m//-ness.
	\2                           # the delimiter again
	(([^\$\\]|\\.|\$[1-9\&\+\'\`\/\=])*?)
				     # the replacement: (anything but '\' or
				     # '$'), or '\.', or $[1-9] (non-greedy)
	)			     # end of fancy m//-ness.
	(\2([iegdxisc]*))?           # optional delimiter again and flags
	\s*$%x ) {                   # trailing whitespace okay

	    # more changes for m// :/
	    utility::debug( "match $op$delimiter$pat$delimiter"
		.($op eq 'm' ? "$flags " : "$repl$delimiter$flags ")
		."  -   $op / $pat /"
		.($op eq 'm' ? " $flags" : " $repl / $flags") . "\n" );

	    # apparently I wanted to quote single ticks.  Perhaps I meant to
	    # quote backticks?
	    # I think this was because people use single ticks a lot in
	    # contractions, don't they?
	    # JZ: I don't use contractions, they're lazy.
	    $pat =~ s!\'!\\\'!;
	    if( $op ne 'm' ) { $repl =~ s/\'/\\\'/g }

	    # for each of the messages that we remember from this user
	    MESSAGES: foreach my $i ( 0 .. $#last ) {

		# testmsg is the only variable allowed into the compartment,
		# supposedly.
		$testmsg = $last[$i];
		# evaluate the regexp inside an allegedly "Safe" compartment.
		# again, sideways hacks for m//
		if ($saferes = $compartment->reval( 
		    "print 'DEBUG $op/$pat"
		    . ($op eq 'm' ? "/$flags" : "/$repl/$flags") # hack
		    . " ', \"\$testmsg\n\"; "
		    . "\$testmsg =~ $op$delimiter$pat"
		    . ($op eq 'm'
			? "$delimiter$flags"
			: "$delimiter$repl$delimiter$flags; \$testmsg")
		    . ";" )) {

		    # if we changed anything, consider it a good match
		    # JZ: but m// won't change anything. hmm.
		    # JZ: so my horribly crufty and just plain wrong solution
		    # JZ: is to return the match status for m// and $testmsg for
		    # JZ: everything else. then i set $saferes to $testmsg.
		    # JZ: i'm very sorry. but hey, it works...
		    if ($op ne 'm' ? $last[$i] ne $saferes
			    : ($saferes and ($saferes = $testmsg))) {
			# but don't allow newlines
			$saferes =~ s/\n/ /g;	# because dev was poking me with
						# it.
			$last[$i] = $saferes;	# and keep the changed line
			$store->nv_store($thisuser, \@last);

			# this is anti-looping tech
			$recent_re{$thismsg}++;
			if ((time - $lastre_time) > 10) { 
			    %recent_re = ();
			    $lastre_time = time;
			} else { 
			    $lastre_time = time;
			    if ($recent_re{$thismsg} == 2) {
				utility::spew($thischan, $thisuser,
				    "Possible looping detected.");
			    }
			    if ($recent_re{$thismsg} >= 2) {
				last MESSAGES;
			    }
			    print "looping code: $thismsg "
				. "$recent_re{$thismsg}\n";
			}

			# output the result
			if ($slashflags =~ m:^$delimiter:) {   # if the trailing slash isn't missing, i.e. s/foo/bar
			    utility::spew($thischan, $thisuser, $saferes);
				# output it 
			} else {
			    utility::spew($thischan, $thisuser,
				"$saferes  (Malformed regexp; tried to DWIM.)");
			}


			last MESSAGES;        # break on good replace
		    }			
		}
	    }
        }
 
    
    elsif ($thismsg =~ /^\s*correction.*help/) {
	utility::spew($thischan, $thisuser,
	    "Just use a s/foo/bar/ regexp and I'll spell it out for you.");
	
    } else { # for normal messages, just log 'em into $last{$thisuser} (an arrayref)

	unshift @last, $thismsg;

	if ($#last > 10) {
	    pop @last;
	}

	# store it
	$store->nv_store( $thisuser, \@last );

    }

}

sub emote {
}

sub private {
}

sub public {
    do_parse( @_ );
}

1;
