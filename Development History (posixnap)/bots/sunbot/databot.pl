#!/usr/local/bin/perl5.6.1

#use warnings;
use strict;
use IO::Socket;

my ($load, $crapola, @load, $blah, $uptime, $return, @df, $free);

$|++;

#fork and exit;

my $server = IO::Socket::INET->new(LocalPort => '7555',
				   Type      => SOCK_STREAM,
				   Reuse     => 1,
				   Listen    => 10 )
	or die "Couldnt create socket on port 7555: $!\n";
sub getload {
	chomp ($load = qx{ /usr/bin/uptime });
	#print $load;
	$uptime = $load;
	$uptime =~ s/^(.*?)up\s+(.*?)\s+\d+\s+user(.*)$/$2/;
	$load =~ s/^(.*?)averag(.*?)\:\s+(\d+\.\d+),\s+(\d+\.\d+),\s+(.*)$/$3 $4/;
	my $return = "uptime: ".$uptime."\nloads: ".$load;
	return $return;
}
sub getio {
	@load = qx{ /usr/bin/iostat 1 2};
	$blah = $load[3];
	chomp $blah;
	$blah =~ s/^(.*?)(\d+)\s+(\d+)\s+(\d+)\s+\d+$/$2;$3;$4/;
	$return = "cpu: ".$blah;
	return $return;
}
sub getdf {
	@df = qx { df -k };
	chomp( my @got = grep /dsk/, @df);
	return @got;
}
sub getmem {
	my @mem = qx{vmstat 1 2};
	$free = $mem[3];
	$free =~ s/^\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+.*$/$1;$2/;
	return $free;
}
while (my $client = $server->accept()) {
	$crapola = getload()."\n".getio()."\nmounts: ";
	$client->send($crapola);
	my @gotta = getdf();
	foreach (@gotta) {
		$_ =~ s/^(.*)\s+(\d+)\s+(\d+)\s+(\d+)\%\s+(.*)$/$5=>$4;$2;$3 /;
		$client->send($_);
	}
	$crapola = "\nfreemem: ".getmem()."\n";
	$client->send($crapola);
}
