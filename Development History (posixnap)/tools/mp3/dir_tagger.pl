#!/opt/perl/bin/perl

use warnings;
use strict;

#
# dir_tagger
#
# will set the id3v2 tag for an entire directory of files.
# this is built on the assumption that youve already organized
# your files, but your player organizes by tags instead of
# filenames (such as iTunes, xmms, or Audion).
#
# usage:
# 
# dir_tagger.pl dirname 'artist name' 'album name' [ use force? ]
#
# "use force" is simply a boolen. when passed a true fourth value,
# it will override the id3v2 tags in a series of files. note that if
# even one tag is encountered, it will refuse to work on any of them.
#

# http://search.cpan.org/CPAN/authors/id/T/TH/THOGEE/tagged-0.40.tar.gz

use File::Slurp;
use MP3::Tag;

my ($Pdir, $Partist, $Palbum, $Pforce) = (@_); # globals

my @targets = read_dir( $Pdir );
my %info = ();

foreach my $wabbit (@targets) {
	my $mp3 = MP3::Tag -> new( $wabbit );
	defined $mp3 -> {ID3v2} and $info{ $wabbit } = $mp3 -> {ID3v2}; # hashref
	die "$wabbit had an id3v2 tag, cowardly refusing to continue." unless $Pforce;
}
