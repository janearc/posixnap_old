#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.shemp.com/";
my @sites = qw{ shemp004.htm };

my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("$host$_")) {


#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^[0-9]+ <A HREF=([^>]+)>([^<]+)<\/A>$/) {
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

