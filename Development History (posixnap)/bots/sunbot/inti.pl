#!/usr/bin/perl -w

# Inti - Incan Sun God. Appropriate no?
# Based on the 11/18 infratructure meeting. Initial write on the sun bot. 
# Inti hopes to be a portable OS independent system monitoring tool so we can
# be proactive when common problems arise.
# Will work on portability to other OS' later.

use strict;
use Net::SMTP;
use File::Slurp;
use Sys::Hostname;

my ($cfile, $log, $psflag, %notrunning, @return, %fswarn, $dfflag, $sunos, $bsd);

$|++;

print "Importing config file\n";


unless ($cfile = $ENV{INTICONF}) { $cfile = q{ /etc/inti/config }; }

my %conf = map { /^(\w+)\s+(.*?)$/ ? ($1 => $2) : () } read_file("$cfile"); 

unless ($log = $conf{error_log}) { $log = q{/var/adm/inti_error.log}; };

open (STDERR,">> ".$log ) || die "Couldnt start error log redirect Error: $!";

print "\nDetecting OS.. ";

# Ugh system calls suck. Consider this broken until I can determine a better way.

chomp(my $uname = qx{ uname -s });

print "$uname detected from uname\n";

print "Detecting hostname..";

chomp(my $hname = hostname);

print " $hname lifted from hostname.\n";

unless ( $uname =~ /[SunOS|Darwin]/ ) {
	print "Currently only SunOS and Darwin are supported.";
	exit 255; # Tell the shell WHOAH there.
}
if ($uname =~ /SunOS/) {
	$psflag = q{ps -ef};
	$dfflag = q{df -k};
	$sunos = 1;
	print "Setting SunOS Compatability\n";
}
else {
	$psflag = q{ps -ax};
	$dfflag = q{df -k};
	$bsd = 1;
	print "Setting non-SunOS Compatibility\n";
}

print "Daemon initialized.\n"; 

$SIG{HUP} = sub {exit 0};


fork and exit;

sub MAILERR {
	my $smtp = Net::SMTP->new("$conf{smtpserver}");
	$smtp->mail($conf{mailuser});
	$smtp->to($conf{admin_email});
	$smtp->data();
	$smtp->datasend("To: $conf{admin_email}\n");
	$smtp->datasend("From: $conf{mailuser}\n");
	$smtp->datasend("Subject: Inti Error Report for $hname\n\n");
	$smtp->datasend(@_);
	$smtp->dataend();
	$smtp->quit();
}	


sub DAEMONCHK {
	my @list = split /\,/, $conf{daemon_list};
	map { s/[\(|\)]//g } @list;
	undef @return;
	my @procs = qx{ $psflag };
	foreach (@list) {
		unless ( grep {/$_/} @procs ) {
			$notrunning{$_}++;
		}
	}
	if (%notrunning) {
		foreach (keys %notrunning) {
			push @return, "$_ found not running\n";
		}
		undef %notrunning;
		return @return;
	}
	return;
}

sub FILESYSCHK {
	my @list = split /\,/, $conf{filesystems};
	undef @return;
	foreach (@list) {
		chomp(my @df = qx{ $dfflag $_ });
		shift @df;
		$df[0] =~ s/^(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%(.*)$/$5/;
		unless ($df[0] > $conf{warn_percent}) { next; }
		unless ($df[0] > $conf{crit_percent}) {
			$fswarn{$_} = "$_ has gone above the warning threshold";
			next;
		}
		$fswarn{$_} = "$_ is now above the critical threshold.";
	}
	if (%fswarn) {
		foreach (keys %fswarn) {
			push @return, $fswarn{$_};
		}
		undef %fswarn;
		return @return;
	}
	return;
}

sub PHYMEMCHK {
	my @vmstat = qx{ vmstat 1 3 };
	shift @vmstat; shift @vmstat; shift @vmstat; # erf this is ugly
	my ($swap, $free) = map{ /^\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)(.*)$/ ? ($1, $2) : () } @vmstat;
	unless ($swap < $conf{crit_swap} && $free < $conf{crit_free}) { return; }
	my $return = "Low memory detected, SwapFree \= $swap  FreeMem \= $free";
	return $return;
}

sub LOADCHK {
	my $load = qx { uptime };
	$load =~ s/^(.*?)averag(.*?)\:\s+(\d+\.\d+),\s+(.*)$/$3/;
	unless ($load > $conf{warn_load}) { return; }
	unless ($load > $conf{crit_load}) { 
		return qq{Current load has surpassed the warning level. Load\: $load};
	}
	return qq{Current load has surpassed the critical level. Load \: $load};
}

for (;;) {
	sleep $conf{interval}; 
	my @trouble;
	unless ($uname =~ /Darwin/) { push @trouble, PHYMEMCHK(); }
	push @trouble, LOADCHK();
	push @trouble, FILESYSCHK();
	push @trouble, DAEMONCHK();
	if (@trouble) { MAILERR(@trouble); }
	undef @trouble;
}
