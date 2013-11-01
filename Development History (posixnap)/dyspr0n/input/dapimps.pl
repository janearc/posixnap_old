#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://dapimps.com/";
my @sites = qw{ index.shtml }; 
#		archive/amateur.html archive/babe.html archive/blonde.html archive/busty.html 
#		archive/ebony.html archive/fetish.html archive/gay.html archive/group.html archive/hardcore.html 
#		archive/interracial.html archive/lesbian.html archive/mature.html archive/oral.html archive/teen.html
#		archive/variety.html};

my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("$host$_")) {
#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^[^<]+<a href='([^']+)'>([^<]+)<\/a>[^<]+<BR>$/) {
#				next unless $url =~  s/.*url=//;
				$date="now";
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/[0-9]+ pi\w+//g;
				$desc =~ s/\.$//g;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				$desc =~ s/\([^\)]+\)//;
				$url =~ s/.*url=//g;
				$url =~ s/&.*//g;
				next unless $url =~ /^http/i;
				pr0n::consider( ($url,$desc,$date) ) unless $ARGV[0];	
				print "pr0n::consider( ($url,$desc,$date) ) \n" if $ARGV[0];
			}	
#		}
	}	
}

pr0n::fin();

