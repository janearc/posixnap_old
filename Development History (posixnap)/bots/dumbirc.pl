#!/usr/bin/perl -wT

# Meet amanda, amanda is the first incarnation of the muzbot series. Amanda simply
# spits out volkswagen part numbers to an IRC channel. Fun for the VW folks.
# todo::
# * make easily readable
# * make more portable
# * convert to POE

use strict;
use warnings;
use Net::IRC;
use Data::Dumper;
use Net::Finger;
use DBI;

my $server = "irc.type2.com";
my $port = 6667;
my $nick = "DumbIRCbot";
my $ircname = "Perl Chainsaw 1.0.1";
my $self;
my @fortune;
my @row;
my @parts;
my $count;
my $search;
my @searches;

undef $ENV{PATH};
$|++;

my $dbh = DBI->connect("dbi:Pg:dbname=vwparts;host=localhost", "tyler")
	or die DBI->errstr();

END { $dbh->disconnect() }

my @ping = ("Yes, -name-?",
	    "Am I still here?",
	    "eh?");

sub getfort {
	my @fort = qx{/usr/games/fortune wisdom};
	return @fort;
}

sub on_connect {
	my $self = shift;
	$self->join("#buslist");
}
sub on_message {
	print $_[0];
	print $_[1];
}
sub tehmagic {
	my $hit;
	my ($self, $event) = @_;
	my @to = $event->to;
	my ($nick, $mynick) = ($event->nick, $self->nick);
	my ($arg) = ($event->args);
	print "<$nick> $arg\n";
	my $sth3 = $dbh->prepare("insert into log (who, quip, stamp) values (?, ?, ?)");
	$sth3->execute($nick, $arg, time());

	if ($arg =~ /amanda/i) {
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
			$arg =~ s/^amanda\s+seen\s+(\w+)(.*)$/$1/i;
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
			if ($nick =~ /muzak/i) {
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
		if ($arg =~ /fortune/i) {
			$hit++;
			undef @fortune;
			@fortune = getfort();
			while (scalar(@fortune) > 4) {
				undef @fortune;
				my @fortune = getfort();
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
	if (!$hit) {
		my $randstat = int(rand()*scalar(@ping));
		my $msgout = $ping[$randstat];
		$msgout =~ s/-name-/$nick/g;
	#	$self->privmsg([ @to ], $msgout);		
	}
	}
	undef $hit;
}
			

my $irc = new Net::IRC;
my $conn = $irc->newconn(Nick => 'amanda',
		      Server => 'irc.type2.com',
                      Port => 6667,
		      Ircname => 'Perl Chainsaw');

$conn->add_global_handler('376', \&on_connect);
$conn->add_handler('msg', \&on_msg);
$conn->add_handler('public', \&tehmagic);

foreach (;;) { $irc->start; sleep 30; };

