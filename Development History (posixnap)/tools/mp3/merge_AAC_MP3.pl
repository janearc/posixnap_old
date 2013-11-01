#!/usr/bin/perl

=head1 NAME

merge_AAC_MP3.pl

=cut

=head1 ABSTRACT

A script to "merge in" a directory of AAC files to a directory
containing files which are stored in MP3 format.

=cut

use warnings;
use strict;
use File::Find;
use Data::Dumper;

my ($newDir, $oldDir) = (@ARGV);

=head1 ARGUMENTS

./merge_AAC_MP3.pl new_dir old_dir holding_dir

=cut

=item new_dir

This argument is to be a directory (absolute or relative) containing
subdirectories organized by Artist/Album/File.m4a. This is the way 
that iTunes stores its data.

=item old_dir

This argument is to be a directory (absolute or relative) containing
subdirectories organized by Artist/Album/File.mp3. This is the way
that iTunes stores its data.

=item holding_dir

This is the directory the MP3 files will be written to after they are
replaced by the corresponding AAC (m4a, m4p) files.

=cut

my $key;
my %FFindSucks = ( new => [], old => [] );
$key = "new"; find( { wanted => \&cull }, $newDir );
$key = "old"; find( { wanted => \&cull }, $oldDir );

my @newFiles = map { Tune -> new( $_ ) } @{ $FFindSucks{"new"} };
my @oldFiles = map { Tune -> new( $_ ) } @{ $FFindSucks{"old"} };

my @moves = map { my $me = $_; $me -> dtrt( $me, $_ ) for @oldFiles } @newFiles;

print Dumper \@moves;

exit 0;

sub cull {
	my $file = \$File::Find::name;
	my $dir  = \$File::Find::dir;

	return () unless $$file =~ /\.(mp3|m4[ap])$/i;
	push @{ $FFindSucks{$key} }, $$file;
	return "FUCK YOU FILE::FIND";
}

package Tune;

sub new {
	my $class = shift;
	my $file = shift;

	return () unless $file =~ /\.(mp3|m4[ap])$/i;
	return bless { me => $file }, $class;
}

sub basename {
	my $self = shift;
	my $file = $self -> {me};
	$file =~ /([^\\\/]*)$/;
	return $1;
} 

sub dirname {
	my $self = shift;
	my $file = $self -> {me};
	$file =~ /(.*[\\\/])[^\\\/]*$/;
	return $1;
}

sub name {
	shift -> {me};
};

sub is_newer { 
	my $self = shift;
	my $test = shift;
	return 0 unless ($self =~ /\.m4[ap]$/i and $test =~ /\.mp3/i);
}

sub dtrt {
	my $self = shift;
	my $test = shift;
	if ($self -> basename() eq $test -> basename()) {
		if ($self -> is_newer( $test )) {
			return [ $self -> name(), $test -> name() ];
		}
	}
	else {
		return ();
	}
}

1;
