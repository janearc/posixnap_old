#!/usr/bin/perl
use strict;
require "pr0n.pl";



my ($url,$desc,$date);

my $host= "http://www.snakesworld.com/";
my @sites = qw{ links.html };

my @data;

foreach (@sites) {
	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {


#	print "*******************\n$_\n";
			if ( ($url,$desc) = /<A href="(http:[^"]+)"><FONT[^>]+>([^<]+)<\/FONT><\/A>/i) {
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/Thumbs//;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				pr0n::consider( ($url,$desc,'now') ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

