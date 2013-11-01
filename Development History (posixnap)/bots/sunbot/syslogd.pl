#!/usr/bin/perl 

# setup needed modules.
use warnings;
use strict;
use DBI;
use IO::Socket;
use Data::Dumper;

$|++; # No buffering plz kthx
$SIG{HUP} = 'IGNORE'; # solaris likes to kill all of your processes when you exit with a HUP

fork and exit;

my $dbh = DBI->connect("dbi:Pg:dbname=syslogs;host=172.17.54.254", "tyler");

# setup some sql queries for later
#This one inserts the log entry.
my $storelog = $dbh->prepare("insert into current_logs (host, ip, log) values ( ? , ? , ? )");
#this two are for updating the hosts table.
my $gethost = $dbh->prepare("select hostname from hosts where ip ~* ?");
my $storehost = $dbh->prepare("insert into hosts (hostname, ip) values ( ? , ? )");

# Masquerade as the syslogd daemon
my $server = IO::Socket::INET->new(LocalPort => 514,
				   Proto => 'udp')
	or die "Couldnt listen on UDP 514, $!\n";

my %cachedhosts; # used to keep hosts in a hash so we dont keep hammering the name servers.

while (my $length=$server->recv(my $data, 65536, 0)) { # now is the time on sprockets when we wait
	die "sysread: $!" if (!defined($length));
	chomp $data;
	
	# data hygeine there has to be a better way!
	$data =~ s/(-|\"|<.*>)//g; #damn pix
	$data =~ s/^\w{3}\s+\d+\s+\d+:\d+:\d+//; # damn pix
	$data =~ s/^\w{3}\s+\d+\s+\d+\s+\d+:\d+:\d+:\s+//; #damn cabletrons
	$data =~ y{A-Za-z0-9_=/\\. }{}cd;

	# Some magic debugging.
	print $server->peerhost() . "\n" unless ($data =~ /pix/i || $data =~ /firewall/ );
	print Dumper $data unless ($data =~ /pix/i || $data =~ /firewall/ );
	
	# I think this was nifty but some guru can do this in one line I just know it.
	if (!$cachedhosts{$server->peerhost()}) { 
		$gethost->execute( $server->peerhost() );
		while (my $row = $gethost->fetchrow_array) {
			$cachedhosts{$server->peerhost()} = $row;
		}
		unless ($cachedhosts{$server->peerhost()}) {
			my $host = gethostbyaddr(inet_aton($server->peerhost()), AF_INET);
			if (!$host) { $host = qq{unknown.} . $server->peerhost(); }
			$cachedhosts{$server->peerhost()} = $host;
			$storehost->execute( $host, $server->peerhost() );
		}
	}
	# Sometimes the cleaning above leaves nothing behind. 
	# the sonicwall is notorious for sending absolute junk to syslog.
	unless ($data =~ /^$/) {
		$storelog->execute( $cachedhosts{$server->peerhost()},  
										$server->peerhost(), $data );
	}
}

# in case we escape
$dbh->disconnect();

