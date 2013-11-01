#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.hardcore-world.com/galleries/";
my @sites = qw{ amateur.html anal.html babe.html bigtits.html ebony.html fetish.html
		group.html hardcore.html illu.html lesbian.html panty.html pantyhose.html 
		pissing.html pregnant.html public.html teen.html toys.html};

my $foo;
my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("$host$_")) {


#	print "*******************\n$_\n";
			if ( ($foo,$url,$desc) = /^([^<]+)<a href="([^"]+)">([^<]+)<\/A><br>\x0d$/) {
				next unless $url =~  s/.*url=//;
				$desc = "$foo$desc";
				$date="now";
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/[0-9]+ pi\w+//g;
				$desc =~ s/\.$//g;
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

