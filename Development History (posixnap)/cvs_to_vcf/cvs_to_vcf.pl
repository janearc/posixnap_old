#!/usr/bin/perl

use warnings;
use strict;
use File::Slurp;

my $source = shift;

foreach my $line (read_file( $source )) {
	my ($fullname, $phone, $email, $cell, $aim) = split /,/, $line;
	my ($firstname, $lastname) = split / /, $fullname;
	open OUTPUT, ">vcfs/$fullname.vcf";
	print OUTPUT << "TEMPLATE";
BEGIN:VCARD
VERSION:3.0
N:$lastname;$firstname;;;
FN:$fullname
ORG:BAE Systems;
EMAIL;type=WORK;type=pref:$email
TEL;type=WORK;type=pref:$phone
X-AIM;type=WORK;type=pref:$aim
END:VCARD
TEMPLATE
	close OUTPUT;
}
