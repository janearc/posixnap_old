#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.stephans.dk";
my @sites = qw{ ?frame=1&popup=0 };

my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("$host/$_")) {
#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^[^<]+<a href="([^"]+)" *>([^<]+)<\/a>/) {
				next unless $url =~  s/.*url=//;
				next unless $url =~  /^http/;
				$date="now";
				$desc =~ y/A-Z/a-z/;
#				$desc =~ s/[0-9]+ pi\w+//g;
				$desc =~ s/\.$//g;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				$desc =~ s/\([^\)]+\)//;
				pr0n::consider( ($url,$desc,$date) ) unless $ARGV[0];	
				print "pr0n::consider( ($url,$desc,$date) ) \n" if $ARGV[0];
			}	
#		}
	}	
}

pr0n::fin();

