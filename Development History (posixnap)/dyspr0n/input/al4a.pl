#!/usr/bin/perl
use strict;
require "pr0n.pl";



my ($url,$desc,$date);

my @sites = qw{ http://www.al4a.com/links.html  };

foreach (@sites) {
	foreach (pr0n::fetchsite($_)) {


			if ( ($date,$url,$desc) = /^([0-9]+-[0-9]+)<A HREF="([^"]+)">([^<]+)<\/A>[^<]+<BR>$/ ) {
				my ($mon,$day) = $date =~ /^([0-9]+)-([0-9]+)$/;
				$date = sprintf ("%04d%02d%02d" , 1900+(localtime())[5]  ,$mon, $day);
				$date =~ s/-//;
				pr0n::consider( ($url,$desc,$date) ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

