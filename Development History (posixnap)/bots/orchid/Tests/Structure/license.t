#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

our $ORCHID_HOME = $ENV{ORCHID_HOME};

# check to see if our environment is marginally happy
ok( defined $ORCHID_HOME, " ORCHID_HOME variable is set" );

# allow them to have a / or not
my $licFile;
if ( -e $ENV{ORCHID_HOME}."/Support/Doc/LICENSE" ) {
	$licFile = $ENV{ORCHID_HOME}."/Support/Doc/LICENSE";
}
else {
	$licFile = $ENV{ORCHID_HOME}."Support/Doc/LICENSE";
}

# check to see if license is extant
ok( -e $licFile, " LICENSE file exists" );

# check to see if the license contents match our sum.
my $cksumX = qx{ which cksum };
chomp $cksumX;
SKIP: {
	skip('Sorry, we need to have and be able to execute cksum(1) to perform this test.')
		unless ( -e $cksumX and -x $cksumX );

	my $cksum = qx{ $cksumX $licFile };
	# get the sum and length, throw the rest out
	my ($cksum_sum, $cksum_len) = (split /\s+/, $cksum)[0,1];

	is( $cksum_sum, "924323363", " LICENSE contents" );
	is( $cksum_len, "1686", " LICENSE length" );
}
