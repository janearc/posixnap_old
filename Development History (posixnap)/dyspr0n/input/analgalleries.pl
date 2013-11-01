#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.analgalleries.com/";
my @sites = qw{ galleries.html };

my @data;

foreach (@sites) {
	foreach (    split /      </, join ('', pr0n::fetchsite("$host$_"))       ) {
#	foreach (pr0n::fetchsite("$host$_")) {
#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^A HREF="([^"]+)">([^<]+)<\/A> <BR>/) {
				next unless $url =~  s/.*url=//;
				$url =~  s/&p=75$//;
				$date="now";
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/[0-9]+ pi\w+//g;
				$desc =~ s/\.$//g;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				$desc =~ s/\n//g;
				$desc =~ s/^[0-9]*//g;
				$desc =~ s/^ *//g;
				$desc =~ s/\([^\)]+\)//;
				pr0n::consider( ($url,$desc,$date) ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

