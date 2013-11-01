#!/usr/bin/perl
use strict;
require "pr0n.pl";



my ($url,$desc,$date);

my @sites = qw{ http://www.worldsex.com/  };

foreach (@sites) {
	foreach (pr0n::fetchsite($_)) {


			if ( ($url,$desc) = /^<a href="([^"]+)">([^<]+)<\/a><br>\x0d$/ ) {
				pr0n::consider( ($url,$desc,'now') ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

