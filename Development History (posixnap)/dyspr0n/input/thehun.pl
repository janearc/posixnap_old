#!/usr/bin/perl
use strict;
require "pr0n.pl";

my @data = pr0n::fetchsite("www.thehun.net");
#my @data = pr0n::fetchsite("www.thehun.net/November.html");
my ($url,$desc,$date);



foreach (@data) {
        s/<br>/<br>נננ/g;
	foreach (split /נננ/) {
		if ( ($url,$date,$desc) = /^<a href="([^"]+)">(\w+ [0-9]+): ([^<]+)<\/a><br>$/i ) {
			next if ( $url =~ /www\.thumbs-up\.net/ );
			$date = sprintf ("$date, %d" , 1900+(localtime())[5]);
			$desc =~ s/ from \w+$//ig;
			$desc =~ s/\w+ sent this //ig;
			pr0n::consider( ($url,$desc,$date) ) ;
		}
	}
}

pr0n::fin();

