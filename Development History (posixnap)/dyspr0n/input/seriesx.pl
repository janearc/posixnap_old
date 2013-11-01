#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.seriesx.com/";
my @sites = qw{ main.shtml  };

my @data;

foreach (@sites) {
	foreach (    split /\(/, join ('', pr0n::fetchsite("$host$_"))       ) {
#	foreach (pr0n::fetchsite("$host$_")) {


#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^[^\)]+[^<]+<a href="([^"]+)">([^<]+)<\/a>/) {
				$url =~  s/.*\|//;
				$url =~  s/\*\*$//;
				$date="now";
				$desc =~ y/A-Z/a-z/;
				$desc =~ s/\x0d|\n/ /g;
				$desc =~ s/ $//g;
				$desc =~ s/  +/ /g;
				$desc =~ s/^ //g;
				pr0n::consider( ($url,$desc,$date) ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

