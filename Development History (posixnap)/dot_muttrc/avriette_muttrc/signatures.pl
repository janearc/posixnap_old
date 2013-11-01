#!/usr/bin/env perl

# $Id: signatures.pl,v 1.1 2004-02-26 13:49:17 alex Exp $

use strict;

my $SIGDIR = $ENV{HOME}."/.signatures";

opendir SIGS, $SIGDIR or die "$0: ack, $!\n";

my @sigs = grep { /\.sig$/ } readdir SIGS;

closedir SIGS or warn "$0: eep, $!\n";

my $thisSig = $sigs[ int rand @sigs + 1 ] || $sigs[ -1 ];

open SIG, "<".$ENV{HOME}."/.signatures/".$thisSig 
	or die "$0: death! $!\n";

my @output = <SIG>;

print @output;

close SIG or warn "$0: eep, $!\n";

exit 0;
