#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "www.link-o-rama.com/greenguy/";
my @sites = qw{ anime.htm newsites.shtml watersports.htm voyeur.htm unusual.htm toys.htm teens.htm 
		sex.htm series.htm redheads.htm pregnant.htm posts.htm pornstar.htm pornstar.htm 
			panties.htm latina.htm interracial.htm groupsex.htm girlgirl.htm gay.htm
		fuckshots.htm boobs.htm bondage.htm blondes.htm black.htm babes.htm anal.htm amateurs.htm};

my @data;

foreach (@sites) {
#	foreach (    split /<A HREF=/, join ('', pr0n::fetchsite("http://$host/$_"))       ) {
	foreach (pr0n::fetchsite("http://$host/$_")) {
#	print "*******************\n$_\n" if $ARGV[0];
			if ( ($url,$desc,my$foo) = /^<li><a href="([^"]+)">([^<]+)<\/a>( [^\.<\n\r]+)/) {
				$desc="$desc$foo";
#				next unless $url =~  s/.*url=//;
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

