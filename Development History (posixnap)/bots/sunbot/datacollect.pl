#!/usr/local/bin/perl

#$ENV{PATH} = "/home/tyler/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/bin:/opt/sbin:/opt/ruby/bin:/usr/local/pgsql/bin:/usr/local/jdk1.2-blackdown/bin:/usr/X11R6/bin:/usr/local/netscape:/usr/sfw/bin:/usr/sfw/sbin:/usr/ccs/bin:/usr/perl5/5.6.1/bin";

#$ENV{LD_LIBRARY_PATH} = "/usr/local/lib:/usr/lib:/usr/openwin/lib:/usr/local/pgsql/lib:/usr/local/openssl/lib";

$|++;

open (STDERR, ">> /export/home/tyler/data.error");

use warnings;
use strict;
use DBI;
use IO::Socket;

my $dbh = DBI->connect("dbi:Pg:dbname=sys_monitor;host=172.17.54.254", "tyler") 
	or die ("Couldnt connect to database! $!");

my @tables = grep { !/^pg_/ } $dbh->tables;

foreach (@tables) {
	my $sth = $dbh->prepare("insert into $_ (uptime, load, mounts, mem, cpu) values
				  ( ? , ? , ? , ? , ? )");
	my $sock = new IO::Socket::INET (
					  PeerAddr => "$_",
					  PeerPort => 7555,
					  Proto => 'tcp'
					);
	unless ($sock) { warn "couldnt connect to $_: $!"; next;}
	my %toins = map{ /^(.*?):\s+(.*)\n$/ ? ($1 => $2) : () } <$sock>;
	close $sock;
	$sth->execute($toins{uptime}, $toins{loads}, $toins{mounts},
		     $toins{freemem}, $toins{cpu});
}

$dbh->disconnect;

