#!/usr/bin/perl
use strict;
require "pr0n.pl";



my ($url,$desc,$date);

my $host= "http://www.absolut-series.com/";
my @sites = qw{ absolut.html };

foreach (@sites) {
	foreach (pr0n::fetchsite("$host$_")) {


			if ( ($url,$desc) = /^[0-9]+ - <a href="(http:[^"]+)">([^<]+)<\/A><br>$/i) {
				$desc =~ y/A-Z/a-z/;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				pr0n::consider( ($url,$desc,'now') ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

