#!/usr/bin/perl -w

$|++;

use constant DEBUG => 0;
use constant DATAFILE => "../example_files/nodes.txt";

use strict;
use warnings;
use Clone qw/clone/;
use Data::Dumper;
use PuzzleSolver::Graph::Node;
use PuzzleSolver::Graph::Container;
use PuzzleSolver::IO::Read;

print <<EOF;

This program finds the shortest path between
two graph nodes.  For more info, read 'README'.

EOF

my $in = PuzzleSolver::IO::Read-> new();

print "reading data from '".DATAFILE."'...";
my $c = $in -> read_node_container_from_file(
    DATAFILE );
print "done\n";

print <<EOF;

I will now attempt to find the shortest path.
This may take some time because I will try every
possible path.  If there is no path between the
nodes, I will tell you that.

The expected result is:
    0 => 3
    3 => 2
    2 => 4

    cost of: 3

NOTE: If the datafile is changed, this information
may be incorrect.

EOF

my $path = best_path( current => $c -> node(0), goal => $c -> node(4) );

if ( $path ) {
    print "Best path found:\n";

    foreach my $n ( @{ $path -> {path} } ) {
        print "\tStep: ", $n -> serial(), "\n";
    }

    print "This path has a cost of: ",
        $path -> {cost}, "\n";
} else {
    print "No paths exist between the given nodes\n";
}

exit;

sub best_path {
    my %args = @_;

    my $current = $args{ current };
    my @closed = @{ clone $args{closed} || [ ] };
    push @closed, $current;

    if ( DEBUG ) {
        foreach my $node ( @{ $args{closed} } ) {
            print $node -> serial(), " ";
        }
        print ")\n";
    }

    if ( $current -> is_equal( $args{goal} ) ) {
        DEBUG and  print "goal found with cost ", $args{cost}, "\n";
        return { cost => $args{cost}, path => [ $current ] };
    }



    my @paths;

    foreach my $conn ( @{ $current -> connections } ) {
        DEBUG and print $current -> serial(), ":", $conn -> {node} -> serial(), "\n";
        my $is_closed = 0;
        foreach my $closed_node ( @closed ) {
            if ( $closed_node -> is_equal( $conn -> {node} ) )
                { $is_closed = 1; }
        }

        unless ( $is_closed ) {
            if ( my $p = best_path(
                    current => $conn -> {node},
                    goal => $args{goal},
                    closed => \@closed,
                    cost => ($args{cost} || 0) + $conn -> {weight} ) )
                { push @paths, $p } }
    }

    if ( @paths > 0 ) {
        my $shortest = $paths[0];
        foreach my $p ( @paths ) {
            if ( $p -> {cost} <= $shortest -> {cost} )
                { $shortest = $p }
        }

        return {
            cost => $shortest -> {cost},
            path => [ $current, @{ $shortest -> {path} } ],
        }
    } else {
        return;
    }
}
