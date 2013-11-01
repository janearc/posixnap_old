#!/usr/bin/perl

use warnings;
use strict;

use File::Slurp;
use XML::Simple;

my ($store, $import) = @ARGV;

my @oldSig = map { chomp and $_ } grep { length $_ } read_file( $import );

my %cruft;
my ($name, $title);
my @lines;

foreach my $line (@oldSig) {
	next if $line eq "--";
	if ($line =~ /,/ and not defined $cruft{title}) {
		($name, $title) = split /,/, $line;
		$cruft{title} = $title;
		next;
	}
	push @lines, $line;
}

my $rem = join " ", @lines;

my ($quote, $whom, $comment) = $rem =~ /"([^"]+)" - ([^,]+)(?:\s*,\s*([^,]+))?/;

# print "q - $quote\nw - $whom\nc - $comment\n";

print <<"XML";
		<signature>
			<attribution>$whom</attribution>
			<text>$quote</text>
			<comment>$comment</comment>
		</signature>
XML

exit 0;
