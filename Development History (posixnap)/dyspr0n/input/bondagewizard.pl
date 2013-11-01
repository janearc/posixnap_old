#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "www.bondagewizard.com";
my @sites = qw{ index.shtml };

my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("http://$host/$_")) {
#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^<a href="[^"]+">[^<]+<\/a> - <a href="([^"]+)"[^>]*>([^<]+)<\/a>$/) {
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

