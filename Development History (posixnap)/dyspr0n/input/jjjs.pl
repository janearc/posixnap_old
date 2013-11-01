#!/usr/bin/perl
use strict;
require "pr0n.pl";



my ($url,$desc,$date);

my $host= "http://www.pornno.com/";
my @sites = qw{ main1.html } ;

foreach (@sites) {
	foreach (pr0n::fetchsite("$host$_")) {
		if ( ($url,$desc) = /^[^<]+<a href="(http:[^"]+)">([^<]+)<\/a>/i ) {
			$desc =~ s/\n/ /g;
			$desc =~ s/^[0-9]+ //;
			pr0n::consider( ($url,$desc,'now') ) ;	
#			print "pr0n::consider( ($url,$desc,$date) ) \n";
		}
	}	
}

pr0n::fin();

