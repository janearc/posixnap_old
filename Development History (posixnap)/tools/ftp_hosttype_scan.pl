#!/usr/bin/perl

# $Id: ftp_hosttype_scan.pl,v 1.1 2004-03-14 00:41:42 alex Exp $
# aja // vim:tw=80:ts=2:noet:syntax=perl
# used to scan a network for ftp hosts and what ftp daemon
# they are running. could be adapted to do almost anything.
# takes one argument, a file containing one ip per line.

use warnings;
use strict;

use IO::Socket;
use File::Slurp;

$|++;

my @hosts = read_file($ARGV[0]) or die "$0 hostfile\n";
my %scanned = map { (split / /)[0] => 1 } read_file("hosts.scanned");
my $timer = 1;

my %server;
eval {
	foreach my $thisip (@hosts) {
		chomp $thisip;
		next if $scanned{$thisip};
		print "scanning $thisip\n";
		my $sock = IO::Socket::INET -> new("$thisip:21") or die $@;
		$sock -> timeout(3);
		my $line;
		my $epoch = time();
		do { $line = <$sock> } while (not defined $line or $epoch < (time() - 5));
		print "$line\n";
		$server{$thisip} = $line;
		append_file("hosts.scanned", "$thisip => $line\n");
		undef $sock;
	}
}
