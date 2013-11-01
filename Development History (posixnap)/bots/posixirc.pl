#!/usr/bin/perl -w

# Meet gozer. Gozer is the second incarnation of the muzbot series. Gozer is completely based
# on amanda's code. Gozer was more customized for the needs of the posixnap people but
# still retains the VWDB backend.

# TODO::
# * Planning on rewriting base to support POE and make more readable and portable.
# * Storing the configuration in the database instead of hard-coded.
# * modularizing the functions code


use strict;
use warnings;
use Net::IRC;
use Data::Dumper;
use Net::Finger;
use DBI;

my $chatter;
my $tattle;
my $server = "irc.type2.com";
my $port = 6667;
my $nick = "DumbIRCbot";
my $ircname = "Perl Chainsaw 1.0.1";
my $self;
my @fortune;
my $lastmsg;
my @row;
my @parts;
my $count;
my $search;
my @searches;
my $msgout;
my @msg;
my $who;
my $hit;

undef $ENV{PATH};
$|++;

my $dbh = DBI->connect("dbi:Pg:dbname=vwparts;host=localhost", "tyler")
	or die DBI->errstr();

END { $dbh->disconnect() }

my @ping = ("Yes, -name-?",
	    "Oh really -name-?",
	    "God, damn are you wanting something -name-?",
	    "Ok thats enough fuck off -name-?",
	    "eh? ass",
	    "gozer?",
	    "ass grox?",
	    "ass dev?",
	    "ass seen gozer?",
	    "eh?",
	    "-rand-");

sub getfort {
	my @fort = qx{/usr/games/fortune rj};
	return @fort;
}

sub on_connect {
	my $self = shift;
	sleep 15;
	$self->join("#posix");
}
sub on_msg {
	#print Dumper @_;
	my ($self, $event) = @_;
	my @to = $event->to;
	my ($nick, $mynick) = ($event->nick, $self->nick);
	my ($arg) = ($event->args);
	my ($person) = ($event->userhost);
	if ($arg =~ /join/) {
		$self->join("#posix");
	}
	if ($arg =~ /say/i) {
		$arg =~ s/^(.*?)say\s+(.*)$/$2/;
		$self->privmsg([ '#posix' ], "$arg");
		$tattle = "$nick told me to say $arg";
	}
		
	if ($arg =~ /auth/i) {
		print "hit $nick $person\n";
		$arg =~ s/^(.*?)auth\s+(.*)$/$2/;
		my $sth3 = $dbh->prepare("select password, homedns from authdb where username = ?");
		$sth3->execute($nick);
		while (@row = $sth3->fetchrow_array) {
			print Dumper @row;
			if ($row[0] eq $arg && $person =~ /$row[1]/) {
				print "authed $nick\n";
				$self->mode('#posix', '+o', $nick);
			}
		}
	}
	if ($arg =~ /addop/i) {
		my $sth3 = $dbh->prepare("insert into authdb (username, password, homedns) values (?, ?, ?)");
		my $sth4 = $dbh->prepare("select username from myadmins where username = ?");
		$sth4->execute($person);
		while (@row = $sth4->fetchrow_array) {
			if ($row[0] = $person) {
				if (my ($username, $password, $homedns) = ($arg =~ /^(.*?)addop\s+(.*?)\s+(.*?)\s+(.*?)$/)[1, 2, 3]) {
					$sth3->execute($username, $password, $homedns);
					print "inserted $username, $password, $homedns\n";
				}
			}
		}
	}
	if ($arg =~ /delop/i) {
		my $arg =~ s/^(.*?)delop\s+(.*?)$/$2/;
		my $sth3 = $dbh->prepare("delete from authdb where username =~ '?'");
		$sth3->execute($arg);
	}

				
		
	print "[$nick] $arg\n";
	#print "{$self, $event, @to, $nick, $mynick}\n";
}
sub tehmagic {
	my $hit;
	my ($self, $event) = @_;
	my @to = $event->to;
	my ($nick, $mynick) = ($event->nick, $self->nick);
	my ($arg) = ($event->args);
	print "<$nick> $arg\n";
	if ($nick =~ /r.ck/i) {
		#hygeine that boy
		if ($arg =~ /y[o|0][\s|y]/ig || 
		    $arg =~ /^y[o|0][\s|y]/ig || 
		    $arg =~ /^y[o|0]$/i ||
		    $arg =~ /\:\(/ig ) {
			$self->kick("#posix", $nick);
		}
	}
	my $sth3 = $dbh->prepare("insert into log (who, quip, stamp) values (?, ?, ?)");
	$sth3->execute($nick, $arg, time());
	my $random = int(rand()*500);
	if ($random > 485) {
		print "hit rand\n";
		my $sth = $dbh->prepare("select count(*) from log");
		$sth->execute();
		my @row = $sth->fetchrow_array();
		print @row;
		my $sth2 = $dbh->prepare("select quip, who from log where id = ?");
		my $rand = int(rand()*$row[0]);
		$sth2->execute($rand);
		my @msg = $sth2->fetchrow_array();
		print @msg;
		$msgout = $msg[0];
		$lastmsg = $msg[1];
		print "\n$lastmsg\n";
		if ($chatter =~ /yes/) {
			$self->privmsg([ @to ], "$msgout");
		}
		$hit++;
	}
		
	if ($arg =~ /gozer/i) {
		if ($arg =~ /tattle/ ) {
			$self->privmsg([ @to ], "$tattle");
		}
		if ($arg =~ /chatter/ ) {
			if ($arg =~ /off/ ) {
				$chatter = "no";
				$self->privmsg([ @to ], "$nick chatter mode is now off.");
			}
			if ($arg =~ /on/ ) {
				$chatter = "yes";
				$self->privmsg([ @to ], "$nick chatter mode is now on.");
			}
		}
		if ($arg =~ /last quote/ ) {
			$hit++;
			$self->privmsg([ @to ], "$lastmsg was the brilliant author of that quote.");
		}
		if ($arg =~ /partnum/ ) {
			$hit++;
			$arg =~ s/^(.*?)partnum\s(.*)$/$2/;
			my $sth = $dbh->prepare("select partnum, partname from parts where partnum ~* ?");
			$sth->execute($arg);
			while (@row = $sth->fetchrow_array) {
				push @parts, "[ $row[0] ] $row[1]";
			}
			if (scalar(@parts) > 6) { 
				$self->privmsg([ @to ], "Search returned more then 6 hits please narrow.");
			}
			else {
			foreach (@parts) {
				if (scalar(@parts) > 4) {
					$self->privmsg([ $nick ], "$_");
					next;
				}
				$self->privmsg([ @to ], "$_");
				
			}
			}
			undef @parts;
		}
		if ($arg =~ /partname/ ) {
			$hit++;
			$arg =~ s/^(.*?)partname\s(.*)$/$2/;
			my @searches = split (" ", $arg);
			print Dumper @searches;
			undef $count;
			foreach (@searches) {

				if ($count) {
					$search = "$search and partname ~* \'$_\'";
					$count++;
				}
				else {
					$search = "where partname ~* \'$_\'";
					$count++;
				}
			}
			undef $count;
			print $search,"\n";

			my $sth = $dbh->prepare("select partnum, partname from parts $search");
			$sth->execute();
			while (@row = $sth->fetchrow_array) {
				push @parts, "[ $row[0] ] $row[1]";
			}
			if (scalar(@parts) > 6) {
				$self->privmsg([ @to ], "Search returned more then 6 hits please narrow.");
			}
			else {
				foreach (@parts) {
					if (scalar(@parts) > 4) {
						$self->privmsg([ $nick ], "$_");
						next;
					}
					$self->privmsg([ @to ], "$_");
				}
			}
			undef @parts
		}

		if ($arg =~ /seen/i ) {
			print "$arg\n";
			$arg =~ s/^gozer\s+seen\s+(\w+)(.*)$/$1/i;
			print "$arg\n";
			my $sth4 = $dbh->prepare("select who, quip, stamp from log where who ~* ? order by stamp desc limit 1");
			$sth4->execute($arg);
			my @row = $sth4->fetchrow_array();
			$hit++;
			my $whattime = localtime($row[2]);
			if (@row) {
				$self->privmsg([ @to ], "$row[0] was last seen at $whattime pacific saying, \"$row[1]\"");
			}
		}

			
		if ($arg =~ /bye/i ) {
			if ($nick =~ /sio/i || $nick =~ /muz/i) {
			   $hit++;
                           $self->quit("$nick i want to have your children");
			}
			else {
			   $hit++;
			   $self->privmsg([ @to ], "Where we goin $nick?");
			}
		}
		if ($arg =~ /hello/i) {
			$hit++;
			$self->privmsg([ @to ], "Hello, $nick!");
	 	}
		if ($arg =~ /op/i) {
			$hit++;
			$self->privmsg([ @to ], "$nick, msg me with your auth");
			my @opwant = ( $nick , time() );
		}
		if ($arg =~ /romeo/i) {
			$hit++;
			undef @fortune;
			@fortune = getfort();
			while (scalar(@fortune) > 10) {
				undef @fortune;
				my @fortune = getfort();
				print "Fuck too long\n";
			}
			foreach (@fortune) {
				$self->privmsg([ @to ], $_);
			}
		}
		if ($arg =~ /tao/i) {
			$hit++;
                        my @fortune = qx{/usr/games/fortune tao};
                        foreach (@fortune) {
                                $self->privmsg([ @to ], $_);
                        }
                }

		if ($arg =~ /time/i) {
			$hit++;
			my @date = qx{/bin/date};
			$self->privmsg([ @to ], @date);
		}
		if ($arg =~ /quake/i) {
			$hit++;
			my @quakes = finger("quake\@gldfs.cr.usgs.gov");
			my $lines = scalar(@quakes);
			my $start = $lines - 5;
			$self->privmsg([ @to ], "DATE-(UTC)-TIME    LAT    LON     DEP   MAG  Q  COMMENTS");
			for (1..5) {
				$self->privmsg([ @to ], $quakes[$start + $_]);
			}
		}
		if ($arg =~ /thank/i) { 
			$hit++;
			$self->privmsg([ @to ], "you're welcome $nick.");
		}
		if ($arg =~ /quote/i) {
			$hit++;
			my $input = $arg;
			my ($addressee, $to_quote, $cruft) = $input =~ m/^(.*?)quote\s+(\w+)(.*)$/;
			$to_quote =~ y/[^A-Za-z0-9_ ]//d;
			if (not length $to_quote) {
				$self -> privmsg([ @to ], qq{who?});
				undef @msg; return;
			}
			if (uc $to_quote eq uc 'me') {
				$to_quote = $nick;
			}
			elsif (uc $to_quote eq uc 'gozer') {
				$self -> privmsg([ @to ], qq{"I am the bot that owns you." - gozer});
				undef @msg; return;
			}
			print $to_quote;
			my $sth3 = $dbh->prepare("select who, quip from log where who ~* ? order by random() limit 1");
			$sth3->execute($to_quote);
			my ($lusar, $quote) = map { @{ $_ } } @{ $sth3 -> fetchall_arrayref() };
			# "0" is a valid nick.
			if (length $lusar and length $quote) {
				$self->privmsg( [ @to ], qq{"$quote" - $lusar} );
			}
			else {
				$self -> privmsg([ @to ], "I've never seen $arg, $nick.");
			}
			undef @msg;
		}


	if (!$hit) {
		my $randstat = int(rand()*scalar(@ping));
		my $msgout = $ping[$randstat];
		$msgout = "-rand-";
		if ($msgout =~ /-rand-/) {
			print "hit rand\n";
			my $sth = $dbh->prepare("select count(*) from log");
			$sth->execute();
  			my @row = $sth->fetchrow_array();
			print @row;
			my $sth2 = $dbh->prepare("select quip, who from log where id = ?");
			my $rand = int(rand()*$row[0]);
			$sth2->execute($rand);
			my @msg = $sth2->fetchrow_array();
			print @msg;
			$msgout = $msg[0];
			$lastmsg = $msg[1];
			$msgout =~ s/-name-/$nick/g;
			if ($chatter =~ /yes/) {
			  $self->privmsg([ @to ], $msgout);		
			}
		}
		
	}
	}
	undef $hit;
}
			

my $irc = new Net::IRC;
my $conn = $irc->newconn(Nick => 'gozer',
		      Server => 'irc2.posixnap.net',
                      Port => 6667,
		      Ircname => 'Perl Chainsaw');

$conn->add_global_handler('376', \&on_connect);
$conn->add_handler('msg', \&on_msg);
$conn->add_handler('public', \&tehmagic);

foreach (;;) { $irc->start; sleep 30; };

