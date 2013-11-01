#!/usr/bin/perl
use strict;
require "pr0n.pl";



my ($url,$desc,$date);

my $host= "http://www.tommys-bookmarks.com/";
my @sites = qw{ teens.shtml centerfolds.shtml celebs.shtml pornstars.shtml 
		blacks.shtml voyeur.shtml uniform.shtml  
		fetish.shtml amateurs.shtml hardcore.shtml babes.shtml lesbians.shtml av.shtml toons.shtml};

foreach (@sites) {
	foreach (pr0n::fetchsite("$host$_")) {


			if ( ($url,$desc) = /^<P><A HREF="(http:[^"]+)">[^<]+<\/A> ([^<]+)<\/p>$/i) {
				$desc =~ s/\n/ /g;
				pr0n::consider( ($url,$desc,'now') ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

