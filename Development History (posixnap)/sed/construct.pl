#!/usr/bin/perl

# $Id: construct.pl,v 1.1 2004-03-02 23:22:51 alex Exp $
# NOT FOR DISTRIBUTION

use warnings;
use strict;
use IO::File;

use constant PARENT   => 0;
use constant ENTITY   => 1;
use constant EPOCH    => 2;
use constant CHILDREN => 3;

my $universe = Universe->new( 
	AutoVivify => 1,
	TreeDepth  => 64,
);

# file must look like:
# <epoch second> <entity> <string>
# 1078267204 username i like pie
# |________| |______| |________|

my $fh = IO::File->new "input.txt", "r";
while (<$fh>) {
	chomp;
	$universe->add_tree( split ' ', $_, 3 );
}

package Universe;

sub new {
	my $class = shift;
	my $nodes = { };
	return bless $nodes, $class;
}

sub push {
	

package Tree;
	
sub new {
	my $class    = shift;
	my ($epoch, $entity, $parent) = (@_);
	my $children = [ ];
	return bless [ $parent, $entity, $epoch, $children ], $class;
}

1;
