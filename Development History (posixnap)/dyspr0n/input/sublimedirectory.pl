#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.sublimedirectory.com/";
my @sites = qw{ biglist.htm  };

my @data;

foreach (@sites) {
	foreach (    split /<BR>/, join ('', pr0n::fetchsite("$host$_"))       ) {
#	foreach (pr0n::fetchsite("$host$_")) {


#	print "*******************\n$_\n";
			if ( ($url,$desc) = /<a href=(http[^>]+)>([^<]+)<\/a>$/) {
#				next unless $url =~  s/.*url=//;
				$date="now";
				$desc =~ s/\([^\)]+\)//;
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/\.$//g;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				$desc =~ s/^[0-9]+ \w+ (of)? ?//;
				pr0n::consider( ($url,$desc,$date) ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

