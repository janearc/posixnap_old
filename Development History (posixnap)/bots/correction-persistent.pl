#!/usr/local/bin/perl

require 5.6.0; # update or die.

#use re 'eval';
use MP3::Napster;
use POSIX;
use Safe;
use strict;
our $nap;
our $lastre_time;
our %recent_re;
our %last;
our %pottymouths = map { $_ => 1 } qw(
				      simple_ CATS GeeAudio cjpa narse CaptDan yugolady 
				      );

our @maintainers = qw(LtDan CaptDan CATS narse muzak SIOCADDRT devnull devslut devan0s stenosis wildthing muzak);

our $testmsg ="";
our $compartment = new Safe;
$compartment->permit(':default');
$compartment->share('$testmsg');

# The command line arguments
our ($channel, $server, $port);
if (!($channel = shift)) { $channel = "Bots"; }
if (!($server = shift)) { $server = "localhost"; }
if (!($port = shift)) { $port = "8888" }

our $botname = "correction";
our $chanre = qr/$channel/i;

our %swears = ( cunt=>['luvtunnel','toybox','sheath'],
		fuck=>['fark', 'fudge', 'frag', 'floop', 'flock'],
		fucking=>['fudging', 'freaking', 'flipping', 'fricking'],
		fuckin=>['fudgin', 'freakin', 'slackin'],
		'\bass\b'=>['ash','@$$','butt', 'tuckus'],
		asshole=>['fishpole','ashhill','pooper'],
		shit=>['shift','schist','poop','doodie', 'shazbot'],
		damn=>['dang','drat','curséd','(term of mild anger)'],
		bitch=>['biznatch','blank','witch', 'dogmommie'],
		);

our @swears = sort {length $b <=> length $a} keys %swears;

$0 = "correction";

our $timeout = 300;
$SIG{ALRM} = sub { $nap->private_message($botname, "ping"); alarm $timeout; };
alarm $timeout;


if (0 != fork()) { exit; }

while (1) {
# The initialization
    $nap = MP3::Napster->new("$server:$port") || die;
    $nap->login($botname,'password',$MP3::Napster::LINK_UNK,6698) || warn "Can't log in ",$nap->error;
    $nap->callback(PRIVATE_MESSAGE, \&do_priv_message) ;
    $nap->callback(PUBLIC_MESSAGE, \&do_pub_message) ;
    $nap->callback(USER_JOINS, \&do_join) ;
    $nap->callback(USER_DEPARTS, \&do_part) ;
    $nap->callback(824, \&do_emote) ;  # 824 is MSG_CLIENT_EMOTE
    $nap->join_channel($channel);
    
# Go do it.
    $nap->run;
#sleep 30 before reconnecting
    sleep(31);
}

sub do_part {
    my ($nap,$code,$msg) = @_; 
    if ($msg eq 'Elvis') {
	$nap->public_message("Elvis has left the building.");
    }
}

sub do_join {
    my ($nap,$code,$msg) = @_; 
    if ($msg eq 'Elvis') {
	$nap->public_message("Hail to the King!");
    }
}

sub do_priv_message {
    my ($nap,$code,$msg) = @_; 
    my ($nick);
    ($nick, $msg) = ($msg =~ m/(\S+)\s+(.*)$/);
    if ($nick eq $botname) {return};
    if ($msg =~ m/^\/last (\S+)\s*$/) {
	&show_last($1, $nick);
    } elsif (not do_stdin_command($nap, $msg)) {
	$nap->private_message($nick, "I'm a bot, silly.");
	$nap->private_message($nick, "You can use substitution regexps in a channel");
	$nap->private_message($nick, "and I'll do the substitution for you.");
	$nap->private_message($nick, "Example:  s/thing-you-said/thing-you-meant-to-say/");
	$nap->private_message($nick, "Run 'man perlre' to learn more about regular expressions.");
	$nap->private_message($nick, "Also, you can message me with /last nick");
	$nap->private_message($nick, "To hear the last bunch of things that nick said.");
    }
}

sub do_stdin_command {
   my ($nap, $line) = @_;
   my $result;
   if ($line =~ /^\/(exit|quit)/) {
       $nap->wait_for_downloads;
       $nap->disconnect;
   } elsif ($line =~ /^\/msg (\S*) (.*)$/) {
       if (not $result = $nap->private_message($1,$2)) {
       }
   } elsif ($line =~ /^\/say (.*)$/) {
       if (not $result = $nap->public_message($1)) {
       }
   } else {
       return undef;
   }
   return 1;
}

sub do_emote {
    my ($nap,$code,$msg) = @_;

    $msg =~ s%
	(\#$chanre)                   # the channel
	\ ([[:alnum:]]+)              # a single space, then the nick
	\ "(.*)"$                     # the action
	%$1 $2 $2 $3%x;
    &do_pub_message($nap,$code,$msg);
}


# Alex's suggestion
# my ($delimiter, $from, $to, $modifier) = $_ =~ m{s([/!|:;-])(.*)\1(.*)\1(.*)};    

sub do_pub_message {
    my ($nap,$code,$msg) = @_;
    my ($nick, $channel, $saferes);
    $msg =~ s/[[:cntrl:]]//g;

    ($channel, $nick, $msg) = $msg  =~ m/^\#($chanre) ([[:alnum:]]+) (.*)/;

    ## This is the hairy regexp that matches the patterns
    if (my ($op, $delimiter, $pat, undef, $repl, undef, $slashflags, $flags) = 

#	$msg =~ m%^\#$chanre ([[:alnum:]]+) \s*(s|tr|y)([/!|:;-])(([^\$\\]|\\.)*?\$?)\3(([^\$\\]|\\.|\$[1-9])*?)(\3([iegdx]*))?\s*$%x ) {

	$msg =~ m%
	^\s*                         # optional leading whitespace
	(s|tr|y)                     # the operation
	([/!|:;-])                   # the delimiter
	(([^\$\\]|\\.)*?\$?)         # the pattern: (anything but '\' or '$'), or '\.', non-greedy.  '$' is okay at the end   
	\2                           # the delimiter again
	(([^\$\\]|\\.|\$[1-9\&\+\'\`\/\=])*?)    # the replacement: (anything but '\' or '$'), or '\.', or $[1-9] (non-greedy)
	(\2([iegdx]*))?               # optional delimiter again and flags
	\s*$%x ) {                   # trailing whitespace okay

	# if we aren't talking to ourself
	if ($nick ne $botname) {
	    # apparently I wanted to quote single ticks.  Perhaps I meant to quote backticks?
	    # I think this was because people use single ticks a lot in contractions, don't they?
	    $pat =~ s%\'%\\\'%;
	    $repl =~ s/\'/\\\'/g;

	    # for each of the messages that we remember from this user
	    MESSAGES: for my $i (0..$#{$last{$nick}}) {
		# testmsg is the only variable allowed into the compartment, supposedly.
		$testmsg = $last{$nick}[$i];
		# evaluate the regexp inside an allegedly "Safe" compartment.
		if ($saferes = $compartment->reval( 
"\$testmsg =~ $op$delimiter$pat$delimiter$repl$delimiter$flags; 
\$testmsg;" )) {
		    # if we changed anything, consider it a good match
		    if (not $last{$nick}[$i] eq $saferes) {
			# but don't allow newlines
			$saferes =~ s/\n/ /g; # because dev was poking me with it.
			$last{$nick}[$i] = $saferes;  # and keep the changed line

			# this is anti-looping tech
			$recent_re{$msg}++;
			if ((time - $lastre_time) > 10) { 
			    %recent_re = ();
			    $lastre_time = time;
			} else { 
			    $lastre_time = time;
			    if ($recent_re{$msg} == 2) {
				$nap->public_message("Possible looping detected.");
			    }
			    if ($recent_re{$msg} >= 2) {
				last MESSAGES;
			    }
			}

			# output the result
			if ($slashflags =~ m:^$delimiter:) {   # if the trailing slash isn't missing, i.e. s/foo/bar
			    $nap->public_message($saferes);    # output it 
			} else {
			    $nap->public_message("$saferes  (Malformed regexp; tried to DWIM.)");
			}


			last MESSAGES;        # break on good replace
		    }			
		}
	    }
	}	
    } elsif ($msg =~ /^\s*correction.*help/) {
	$nap->public_message("Just use a s/foo/bar/ regexp and I'll spell it out for you.");
	
    } else { # for normal messages, just log 'em into $last{$nick} (an arrayref)
	
	if (defined $pottymouths{$nick}) {
	    my $mildmesg = &replace_swears($msg);
	    if ($mildmesg ne $msg) {
		$nap->public_message($mildmesg);
	    }
	}

	unshift @{$last{$nick}}, $msg;
	if ($#{$last{$nick}} > 10) {
	    pop @{$last{$nick}};
	}
    }

    if (grep {$_ eq $nick} @maintainers) { 
	
	if ($msg =~ /^\s*!pottymouths\b/) {
	    $nap->public_message("Pottymouths: ".join " ", keys %pottymouths );
	} elsif ($msg =~ /^\s*!pottymouth (\w+)/) {
	    $pottymouths{$1} = 1;
	    $nap->public_message("$1 is a pottymouth.");
	} elsif ($msg =~ /^\s*!unpottymouth (\w+)/) {
	    delete $pottymouths{$1};
	    $nap->public_message("$1 has reformed.");
	}
    }
}


sub show_last {
    my ($nick, $target) = @_;
    for my $i (reverse (0..$#{$last{$nick}})) {
	$nap->private_message($target, "$nick: $last{$nick}[$i]");
    }
}
	
    
	
sub replace_swears {
    my ($line) = @_;

     for my $harsh (@swears) {
	 my $milds = $swears{$harsh};
	 my $mild = $$milds[rand @$milds];
	 $line =~ s/$harsh/$mild/gi;
     }
    return $line;
}


# a clever regexp: s/\b(?!(?:and|an?|o[rf]|the)\b)(\w)(\w*)/\u$1\L$2/g
