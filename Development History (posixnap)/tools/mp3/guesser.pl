#!/opt/perl/bin/perl

use warnings;
use strict;

#
# guesser.pl
# 
# look at a file and attempt to ascertain what its
# vital statistics are from its filename.
#
# usage:
#
# guesser.pl file.mp3 anotherfile.mp3 yetanother.mp3
#

my %examples = (
	"01_The Stallion.mp3" => "trackno, _, songname", # ed sent me a bunch of these
	"01 - Ween - The Stallion.mp3" => "trackno, ' - ', artist, ' - ', songname", # i used to organize them this way
	"The Stallion_01.mp3" => "songname, _, trackno", # ed also sent me a bunch of these.
);
