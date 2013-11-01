#!/usr/bin/perl -w
use strict;
require "pr0n.pl";





my ($url,$desc,$date);

my $host= "http://www.redway.org/";
my @sites = qw{ main.html archive01.html archive02.html 
		archive03.html archive04.html};

my @data;

foreach (@sites) {
#	foreach (    split /<LI>/, join ('', pr0n::fetchsite("$host$_"))       ) {
	foreach (pr0n::fetchsite("$host$_")) {


#	print "*******************\n$_\n";
			if ( ($url,$desc) = /^[^<]+<A HREF="(http:[^"]+)">([^<]+)<\/A>/i) {
				$date="now";
				#$desc =~ y/A-Z/a-z/;
				$desc =~ s/ $//g;
				$desc =~ s/^ //g;
				if ( /\(/ && /\// && /\./) {
#					print "cool link: $_:\n";
					my($foo) = /\(([^\)]+)/;
					if (! $foo eq '') {
#						print "foo is: $foo\n";
						my($from,$to) = $foo =~ /[^0-9]+([0-9]+)[^0-9]+([0-9]+)/;
						if ($to && $from) {
							$desc =~ s/\([^\)]+\)//;
#							print "no_from:$from   no_to: $to \n";
							my $i=$from ;
							while ($i < $to) {
								my $link=$url;
								$i++;
								if ( $link =~ s/$from/$i/ ) {
								pr0n::consider( ($link,$desc,$date) ) ;	
#				print "**** pr0n::consider( ($link,$desc,$date) ) \n";
								}
							}

						}
					}
				}				
				$desc =~ s/\([^\)]+\)//;
				pr0n::consider( ($url,$desc,$date) ) ;	
#				print "pr0n::consider( ($url,$desc,$date) ) \n";
			}	
#		}
	}	
}

pr0n::fin();

