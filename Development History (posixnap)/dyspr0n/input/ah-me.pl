#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.ah-me.com/";
my @sites = qw{ main.html  };

my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("$host$_")) {


#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^[^<]+<a href="([^"]+)">([^<]+)<\/a><br>$/) {
				next unless $url =~  s/.*url=//;
				$date="now";
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				$desc =~ s/\([^\)]+\)//;
				pr0n::consider( ($url,$desc,$date) ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

