#!/usr/bin/perl -w

use strict;
use MP3::Napster;

$SIG{ALRM} = \&ding;		# time to clean up the chatteray
$SIG{INT} = \&hangup;		# on SIGINT, disconnect
$SIG{TERM} = \&hangup;
$SIG{HUP} = \&chat;

our $nap;

my $root = '/home/posixnap/';
our $channel = '#posix';
our $nick = 'topicbot';
our $DB_NAME = 'posixnap';
our $FORTUNE_DB = '/usr/share/games/fortune/' . $DB_NAME;
our $linkfile = $root.'links.dat';
our @chatteray;
our $chatterfile = $root.'chatter.dat';
our %chatterignore;
our $ignorefile = $root.'chatter.ignore';
our $chattertag = $root.'chatter.tag';
our $chatterchat = $root.'chatter.chat';
our %new_topic = (owner => undef, recv => undef);
#our $alrm = 0;

open CHAT, "+>${root}chatter.pid";
print CHAT $$;
close CHAT;

our %funcs = ( 	topic =>	[ \&do_topic, 'returns a random topic',
							":topic             returns a random topic\n" .
							":topic delete      removes the last topic" ],
				chatter => 	[ \&do_chatter, 'sets chatter options',
							":chatter ignore    adds you to the ignore list\n" .
							":chatter unignore  removes you from the ignore " .
								"list\n" .
							":chatter since     date you were added to " .
								"ignore\n" .
	       		    		":chatter tag       sets chatter's tag" ],
				help =>		[ \&do_help, 'returns extended help for a function',
							':help <function>' ],
	     );

my $server;
if ($ARGV[1]) { $server = $ARGV[0] . ':' . $ARGV[1] }
else { $server = '65.166.140.202:7777' }

my $password = get_pass();

while (1) {
	$nap = MP3::Napster->new( $server );
	
	if ($nap) {

		$nap->callback( PRIVATE_MESSAGE, \&message );
		$nap->callback( PUBLIC_MESSAGE, \&message );
		$nap->callback( CHANNEL_TOPIC, \&harvest );
		$nap->callback( INVALID_ENTITY, \&parted );
		#$nap->callback( JOIN_ACK, \&chan_join_ack );
		$nap->callback( 316, \&parted ); # killed
		$nap->callback( 10112, \&links_init );
		$nap->callback( 824, sub {
			my( $nick, $action ) = $_[2] =~ /^\S+ (\S+) "(.+)"$/;
			chatter( 824, $nick, $action );
		} );
		
		my $logged_in = -1;
		while( $logged_in == -1 ) {
			$logged_in = bot_login($password);
			if( $logged_in > 0 ) {
			
				chan_join();
				$nap->error(''); #clear any errors
				links_wipe();
				chatter();	# init the chatter db
				ignore_init();
				
				$nap->send( 10112, '' );
				$nap->run;

			} elsif( $logged_in == -1 ) {
				# i'm really sorry that i had to do it this way.
				# please accept my apologies :(
				$nap->disconnect;
				$password = get_pass();
				$nap = MP3::Napster->new( $server );
			} 
		}

	} else { print STDERR "couldn't connect to $server\n" }
	
	sleep 180; # sleep for 3 minutes before attempting to log in again.
}


print STDERR "Fine. Kill me. See if I care. Jackass.\n";


sub get_pass {
	print 'Password: ';
	system "stty -echo </dev/tty" unless $ENV{EMACS};
	$_ = <STDIN>;
	system "stty echo </dev/tty" unless $ENV{EMACS};
	print "\n";
	chomp;
	return $_;
}



sub bot_login {
	my $login_string = $nick . ' ' . $_[0] . ' 0 "Crackhed Music'
			   . ' Thiever vP" ' . LINK_CABLE;
	my ($event, $msg) = $nap->send_and_wait( LOGIN, $login_string,
						 [ LOGIN_ACK, LOGIN_ERROR,
						 ERROR ], 10 );
	if( !$event ) {
		if( !$msg ) { print STDERR "timeout\n"; return 0 }
		else { print STDERR "$msg\n"; return -1 }
	} elsif( $event == LOGIN_ACK ) { return 1 }
	else { return 0 }
}


# this function actually handles server messages (most of which pertain to
# getting killed
sub parted {
	$_ = $_[2];
	if( /^You were kicked.* (\S+):/o )
		{ chan_join() }
	elsif( /(\S+) cleared channel $channel:/ )
		{ chan_join() }
	elsif( /(\S+) killed $nick:/ )
		{ $nap->disconnect () }
	elsif( $_[1] == 316 )
		{ $nap->disconnect () }
	elsif( /^Server (.+) has joined/ ) {
		print STDERR "Server $1 has joined\n";
		links_wipe();
		$nap->send( 10112, '' );
		#links_add( $1 );
	}
	elsif( /^Server (.+) has quit/ ) {
		#{ links_rm( $1 ) }
		print STDERR "Server $1 has quit\n";
		links_wipe();
		$nap->send( 10112, '' );
	}
	elsif( $new_topic{recv} and /^([^ ]+) set topic/ ) {
		$new_topic{owner} = $1;
	}
}


sub chan_join {
	$nap->part_channel( $channel ); # in case we've been kicked
	$nap->join_channel( $channel ); # or die "can't join $channel: "
		#. ($nap->error ? $nap->error : "$!") . "\n";
	#harvest((my $ch = $nap->channel($channel))->topic);
}


sub hangup () {
	if( $nap ) { $nap->disconnect() }
	# good idea to make note of the fact that i'm offline
	open F, "+>$chatterfile";
	print F "[ sorry, i'm offline ]";
	close F;

	#kill 9, $alrm;
	exit (0);
}


sub harvest {
	(my $quote) = $_[2] =~ /^$channel (.+)$/i;
	$new_topic{owner} = undef;
	$new_topic{recv} = 1;

	print STDERR "got a topic... ";
	
	if( $quote !~ m-(?:f|ht)tp://- ) {#and $quote !~ m/^\s*$/ ) {
		#we don't want this to be full of links...
		open DB, $FORTUNE_DB or do {
			print STDERR "couldn't open the fortune database: $!\n";
			return;
		};
		#my $partial = "";
		while( $_ = <DB> ) {
			# pas des duplicates
			chomp;
			my $line = quotemeta($_);
			$line =~ s-/-\\/-;
			if( "$_" eq "$quote" )
				{ print STDERR "not added\n"; return }
		#	elsif( $quote =~ m/^$line.+/ ) {
		#		print STDERR "partial, replacing... ($_)\n";
		#		$partial = $_;
		#	}
		}
		close DB;
		# no matches, add to database
		#if($partial) {
		#	open TMP, '+>/tmp/fortune.tmp';
		#	open DB, "<$FORTUNE_DB";
		#	while( $_ = <DB> ) {
		#		chomp;
		#		if( $partial eq $_ )
		#			{ $_ = "$quote\n" }
		#		print TMP "$_\n";
		#	}
		#	close TMP;
		#	qx-/bin/mv /tmp/fortune.tmp $FORTUNE_DB-;
		#} else { 
			open DB, ">>$FORTUNE_DB" or do {
				print STDERR "couldn't open the fortune database: $!\n";
				return;
			};
			print DB "%\n$quote\n";
		#}
		close DB;
		qx-/usr/bin/strfile $FORTUNE_DB\{,.dat\}-;
		print STDERR "\"$quote\"\n";
	}
}


sub untaint {
	$_ = $_[0];
	s/(\?|\.|\+|\*|\(|\[|\||\{|\}|\]|\))/\\$1/go;
	s/\\/\\\\/go;
	s/\$/\\\$/go;
	return $_;
}


sub message {
	my( $private, $nick, $message, $chan, $ret );
	if ($_[1] == 205) {
		$private = 1;
		($nick, $message) = $_[2] =~ /^(\S+) (.+)$/o;
	} else {
		($chan, $nick, $message) = $_[2] =~ /^(\S+) (\S+) (.+)$/o;
		chatter( PUBLIC_MESSAGE, $nick, $message );
	}
	if ($message) {
		my( $command, $arguments );

		if( $private ) { (($command, $arguments) =
			$message =~ /^(?::)?(\S+)(?:\s+(.+))?$/o) or return;
		} else { (($command, $arguments) =
			$message =~ /^:(\S+)(?:\s+(.+))?$/o) or return;
		}

		my $iscmd = 0;
		foreach my $cmd (keys %funcs) {
			if( $command eq $cmd ) {
				my $cb = $funcs{$cmd}[0];
				$ret = &$cb( $nick, $arguments );
				$iscmd = 1;
				last;
			}
		}
		
		if( !$iscmd ) { return };

		if( $ret ) {
			my @lines = split /\n/, $ret;
			for( my $i = 0; $i <= $#lines; $i++ ) {
				if( $private or $#lines >= 10 or $command eq 'help' )
					{ $nap->private_message( $nick, $lines[$i] ) }
				else { $nap->public_message( $lines[$i] ) }
			}
		}
	}
}


sub do_topic {
	my $ret;

	if(defined($_[1])) {
		if($_[1] eq 'delete') {
			if($new_topic{owner} and $_[0] eq $new_topic{owner}) {
				open DB, "+<$FORTUNE_DB";
				seek DB, -1, 2;

				my $chr = ':';
				while( $chr ne '%' ) {
					read DB, $chr, 1, 0;
					seek DB, -2, 1;
				}
				truncate DB, (tell DB) + 1;

				close DB;
				qx-/usr/bin/strfile $FORTUNE_DB\{,.dat\}-;
				$ret = "last topic removed";
				print STDERR 'topic deleted by ',
					$new_topic{owner}, "\n";
				undef $new_topic{owner};
			} else { $ret = "You didn't post that topic." }
		} else { $ret = "Um... yes." }

	} else { $ret = `/usr/games/fortune $FORTUNE_DB` }
	chomp($ret);
	return $ret;
}


sub do_chatter {
	my( $nick, $args ) = @_;
	defined $args or return "I need an argument to :chatter.";
	my $ret;
	if( $args =~ /^ignore$/ ) {
		if( not exists $chatterignore{"$nick"} ) {
			$chatterignore{"$nick"} = time;
			$ret = "$nick is being ignored";
			ignore_update();
		} else { $ret = "$nick is already being ignored" }
	} elsif( $args =~ /^unignore$/ ) {
		if( exists $chatterignore{"$nick"} ) {
			delete $chatterignore{"$nick"};
			$ret = "$nick is no longer being ignored";
			ignore_update();
		} else { $ret = "$nick wasn't being ignored" }
	} elsif( $args =~ /^tag (.+)$/ ) {
		open F, "+>$chattertag";
		print F $1;
		close F;
		if( exists $chatterignore{"$nick"} ) {
			$ret = "I thought you were being ignored...";
		}
	} elsif( (my $who) = $args =~ /^since(?:\s+(.+))?$/ ) {
		if( not($who) ) { $who = $nick }
		if( not exists $chatterignore{"$who"} ) {
			$ret = "$who is not being ignored.";
		} else {
			open F, $ignorefile;
			while( $_ = <F> ) {
				if( /^$who (\d+)$/ ) {
					$ret = gmtime($1) . ' UTC';
					last;
				}
			}
			close F;
		}
	}

	return $ret;
}


sub ignore_update {
	open F, "+>$ignorefile";
	while( my @line = each %chatterignore ) {
		print F join( ' ', @line), "\n" if @line;
	}
	close F;
}
	

sub ignore_init {
	open F, $ignorefile or return;
	while( my @ignored = split / /, <F> ) {
		$chatterignore{"$ignored[0]"} = $ignored[1];
	}
	close F;
}


sub links_add {
	my $server = shift @_;
	open LINKS, ">>$linkfile";
	print LINKS "$server\n";
	close LINKS;
}


sub links_rm {
	my $server = shift @_;
	open LINKS, $linkfile;
	open TMP, "$linkfile.tmp";
	while( $_ = <LINKS> ) {
		print TMP unless /$server/;
	}
	close TMP;
	close LINKS;
	`mv -f $linkfile.tmp $linkfile`;
}


sub links_wipe {
	open LINKS, "+>$linkfile";
	close LINKS;
}


sub links_init {
	(my @servers) = $_[2] =~ /^(\S+)\s\S+\s(\S+)/;
	foreach my $server (@servers) {
		my $found = 0;
		open LINKS, $linkfile;
		while( $_ = <LINKS> ) {
			#$found = 1 if /^$server$/;
			#last if $found;
			/^$server$/ and do { $found = 1; last }
		}
		close LINKS;
		do {
			open LINKS, ">>$linkfile" or do {
				error( "couldn't open link file" );
				return;
			};
			print LINKS "$server\n";
			close LINKS;
		} unless $found;
	}
}


sub chatter {
	my( $type, $nick, $yap ) = @_;
	my $change = 0;
	my $now = time;
	my $timeout = 600;
	my $maxlines = 30;

	while( ($#chatteray > -1 and $chatteray[0]{at} != 0) 
	       and $chatteray[0]{at} < $now - $timeout) {
		printf STDERR "expired\n" if not defined $yap;
		shift @chatteray;
		$change = 1;
	}
	
	if( defined $yap ) {
		$change = 1;
		my $line;
		if(exists $chatterignore{"$nick"}) { $line = "--[ ignoring $nick ]--" }
		elsif( $type == PUBLIC_MESSAGE ) {	$line = "($nick) $yap" }
		elsif( $type == 824 ) { $line = "***$nick $yap" }
		my $elem = { at => $now, line => $line };
		push @chatteray, $elem;
		if( $#chatteray == $maxlines - 1 or $chatteray[0]{at} == 0 ) {
			print STDERR "bumped/initted\n"
				if not $chatteray[0]{at};
			shift @chatteray;
		}
	}

	elsif( $#chatteray == -1 ) {
		$change = -1;
		#alarm 0; # don't schedule an alarm if nothing's happening
		my_alarm( 0 );
		push @chatteray, { at=>0, line=>'[ nothing but electrons ]' };
	}
		
	if( $change ) {
		open CHAT, "+>$chatterfile";
		print CHAT map( "$$_{line}\n", @chatteray );
		close CHAT;
		#alarm $timeout - ($now-$chatteray[0]{at}) unless $change == -1;
		my_alarm( ($change == -1) ? 0
			  : ($timeout - ($now - $chatteray[0]{at}) + 10)
			);
		# add 10 to avoid a 0 alarm, and to delete several at once
	}
		
}


sub ding {
	print STDERR "[".localtime(time)."] dong\n";
	chatter();
}


sub my_alarm {
	alarm( $_[0] );
	#$_ = shift @_;
	#$alrm = 0 unless $_;
	#do {
	#	print STDERR "[".localtime(time)."] alarm in ${_}s\n";
	#	kill 9, $alrm if $alrm;
	#	$alrm = `/home/k/bin/alarm.sh $$ $_ &`;
	#} if $_;
}


sub chat {
	if( open F, $chatterchat ) {
		flock F, 2;
		my( $who, $what ) = <F> =~ /^(\S+) (.+)$/;
		close F;
		open F, "+>$chatterchat";
		close F;
		print STDERR "chat: [$who] $what\n";
		$nap->public_message( "[$who] $what" );
	} else { error( "couldn't open chat file" ) }
}


sub error {
	print STDERR "$_[0]: $!\n";
}


sub do_help () {
	if ( $_[1] ) {
		$_[1] =~ /\s*:?(\w+)\s*/;
		foreach my $cmd (keys %funcs) {
			if ($_[1] eq $cmd) {
				return $funcs{$cmd}[2];
			}
		}
	} else {
		my $returnstr = "The following functions are defined:\n";
		foreach my $cmd (keys %funcs) {
			$returnstr .= $cmd . ":" . " "x(11 - length($cmd))
							. $funcs{$cmd}[1] . "\n";
		}
		return $returnstr;
	}
	return "$_[1] is not defined.";
}
