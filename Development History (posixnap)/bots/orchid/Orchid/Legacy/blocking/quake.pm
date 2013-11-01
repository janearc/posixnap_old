use warnings;
use strict;

# XXX: see TODO. http://neic.usgs.gov/neis/bulletin/bulletin.html

sub do_quake {
	my( $command_re, $count, $thischan, $thisuser, $thismsg ) = @_;
	return undef unless $thismsg =~ $command_re;
	my %quakedata = parse_quake();
	my $quakes;
	utility::spew($thischan, $thisuser, "Time Latitude Longitude Depth Magnitude Location");
	for $quakes ( 1 .. $count++ ) {
		if ($quakedata{$quakes}->{stamp}) {
		   utility::spew($thischan, $thisuser, $quakedata{$quakes}->{stamp} . " " . $quakedata{$quakes}->{lat} .
			" " . $quakedata{$quakes}->{lon} . " " . $quakedata{$quakes}->{depth} .
			"km  " . $quakedata{$quakes}->{mag} . " " . $quakedata{$quakes}->{loc});
		}
	}
}	
sub parse_quake {
	use LWP::Simple;
	my $puke = get("http://wwwneic.cr.usgs.gov/neis/bulletin/index.html");
	return undef unless $puke;
	my @vomit = split(/\n/, $puke);
	chomp @vomit;
	my ($spew, $chunk, $eat, %quake, $stamp);

	$|++;

	foreach $chunk (@vomit) {
       	 if ($chunk =~ /\<TR\>/) { $eat++; $spew++; }
       	 if ($chunk =~ /\<\/TR\>/) { $eat--; undef $stamp; }
       	 next unless $eat && ($spew > 1);
       	 if ($chunk =~ /^\<td\s+headers="t1"/) {
       	         $chunk =~ s/&nbsp;/ /g;
       	         ($stamp) = ($chunk =~ /^.*?(\d+\/\d+\/\d+\s+\d+\:\d+\:\d+).*$/);
       	         $stamp =~ s/^.*?\>\s+//;
		 $quake{$spew}->{stamp} = $stamp;
       	         next;
       	 }
       	 if ($chunk =~ /^\<td\s+headers="t2"/) {
       	         ($quake{$spew}->{lat}) = ($chunk =~ /^.*?\>(\d+\.\d+\w)\<.*$/);
       	         next;
       	 }
       	 if ($chunk =~ /^\<td\s+headers="t3"/) {
       	         ($quake{$spew}->{lon}) = ($chunk =~ /^.*?\>(\d+\.\d+\w)\<.*$/);
       	         next;
       	 }
       	 if ($chunk =~ /^\<td\s+headers="t4"/) {
       	         ($quake{$spew}->{depth}) = ($chunk =~ /^.*?\>(\d+\.\d+)\<.*$/);
       	         next;
       	 }
       	 if ($chunk =~ /^\<td\s+headers="t5"/) {
       	         ($quake{$spew}->{mag}) = ($chunk =~ /^.*?\>(\d+\.\d+)\<.*$/);
       	         next;
       	 }
       	 if ($chunk =~ /^\<td\s+headers="t7"/) {
       	         $chunk =~ s/&#.*?>\s+//g;
       	         ($quake{$spew}->{loc}) = ($chunk =~ /^.*?status='.*?'">(.*?\w+.\w+.\w+)\<\/a\>\<\/font\>.*?$/);
       	         next;
       	 }
	 #sometimes depth and mag are undef. because usgs sucks.
	 unless ($quake{$spew}->{depth}) {
		$quake{$spew}->{depth} = "n/a";
	 }
	 unless ($quake{$spew}->{mag}) {
		$quake{$spew}->{mag} = "n/a";
	 }
	}
	return %quake;
}



sub public {
  	do_quake( qr{^:quake}, 5, @_ );
}

sub emote {
}


sub private {
	do_quake( qr{^:?quake}, 9, @_ );
}


sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, <<"HELP" );
:quake returns recent earthquake data. /msg for more results.
HELP
}
