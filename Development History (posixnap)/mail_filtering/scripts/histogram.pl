#!/usr/bin/perl

# $Id: histogram.pl,v 1.1 2004-02-26 02:59:29 alex Exp $

# histogram.pl
# generate a sorted list of how many spams came on which day. assumes
# a maildir dir.

use warnings;
use strict;
use Carp;

my $dir = shift;
my $reader = ReademWritem->new();

warn "slurping...\n";
my @files = map { File->new( $_ ) } $reader->read_dir( $dir );

warn "sorting...\n";
my %unique_days = map { $_->{frag} => 1 } @files;

my %days;

foreach my $day (keys %unique_days) {
	$days{$day} = [ grep $_->{frag} eq $day, @files ];
}

print $_." => ".scalar @{ $days{$_} }."\n" 
	for sort { $days{$a}->[0]->{mtime} <=> $days{$b}->[0]->{mtime} } keys %days;

exit 0;

package ReademWritem;

use Carp;
use Carp::Assert;

sub new {
	my $class = shift;
	return bless [ ], $class;
}

sub read_file {
	my $self = shift;
	my $filename = shift;
	chomp $filename;

	assert( -f $filename and -r $filename );

	open IN, "<$filename" or confess "$filename: $!\n";
	my @in = <IN>;
	close IN;

	@in;
}

sub read_dir {
	my $self = shift;
	my $dir  = shift;
	chomp $dir;

	assert( -d $dir and -r $dir and -x $dir );
	
	opendir IN, $dir or confess "$dir: $!";
	my @files = grep /^[^.]/, readdir IN;
	closedir IN;

	return map { $dir."/".$_ } @files;
}

1;

package File;

use Carp::Assert;

sub new {
	my $class = shift;
	my $filename = shift;
	my $self = bless { }, $class;

	my $reader = ReademWritem->new();

	$self->{contents} = $reader->read_file( $filename );
	$self->{name}     = $filename;
	$self->{mtime}    = [stat $filename]->[9];
	$self->{size}     = [stat $filename]->[7];

	$self->{frag}     = join $", (scalar localtime($self->{mtime})) =~ m!
		(
			[A-Z][a-z][a-z]\s+\d+\s
		)
		.*
		(\d{4}) $
	!x;
	
	return $self;
}

1;
