#!/usr/bin/perl

use warnings;
use strict;

use DBI;
my $dbh = DBI -> connect( "dbi:Pg:dbname=timetracker", "alex", "" )
	or die DBI -> errstr();


my $newtask_sth = $dbh -> prepare( "insert into tasks (beeid, taskname) values (?, ?)" );
my $newbee_sth = $dbh -> prepare("insert into workerbees (bee) values (?)" );

my %tasks = ( t => \&task, b => \&bee );

print +join "\n\t", qw{ root: (t)ask (b)ee };
	print "\n => ";
while (<>) {
	print +join "\n\t", qw{ root: (t)ask (b)ee };
	print "\n => ";
	chomp;
	next unless $_;
	$tasks{$_} -> ();
}

sub task {
	print "taskname => ";
	chomp (my $taskname = <>);
	print "beeid => ";
	chomp (my $beeid = <>);
	$newtask_sth -> execute( $beeid, $taskname );
}

sub bee {
	print "beename => ";
	chomp (my $beename = <>);
	$newbee_sth -> execute( $beename );
}
