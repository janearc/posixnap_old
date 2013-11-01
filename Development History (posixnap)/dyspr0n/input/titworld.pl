#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "www.titworld.net/";
my @sites = qw{ main.htm  };

my @data;

foreach (@sites) {
	foreach (    split /       </, join ('', pr0n::fetchsite("$host$_"))       ) {
#	foreach (pr0n::fetchsite("$host$_")) {
	print "*******************\n$_\n" if $ARGV[0];
			if ( ($url,$desc) = /^A HREF="(http[^"]+)"[^>]+>[^>]+[^ ]+        ([^<]+)<\/FONT><\/A><BR>/) {
#				next unless $url =~  s/.*url=//;
				$date="now";
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/\.$//g;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				$desc =~ s/\([^\)]+\)//;
				$desc =~ s/!//g;
				$desc =~ s/ - .*//g;
				pr0n::consider( ($url,$desc,$date) ) unless $ARGV[0];	
				print "pr0n::consider( ($url,$desc,$date) ) \n" if $ARGV[0];
			}	
#		}
	}	
}

pr0n::fin();

