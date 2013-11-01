package PuzzleSolver::IO::Read;

use strict;
use warnings;
use File::Slurp;
use PuzzleSolver::Geometry::Point;
use PuzzleSolver::Geometry::Line;
use PuzzleSolver::Geometry::Shape;
use PuzzleSolver::Graph::Container;
use PuzzleSolver::Graph::Node;
use PuzzleSolver::Snafooz::Side;
use PuzzleSolver::Snafooz::Piece;

=head1 NAME

PuzzleSolver::IO::Read - An input module for puzzle data

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::IO::Read;

 my $io = PuzzleSolver::IO::Read -> new();

=head1 ABSTRACT

This module creates an input object to be used to read puzzle data.

=head1 INPUT FORMAT

Currently only two types of data can be read from a file, point data and line data.  Point data is denoted by C<P:> and is read in x,y format.  Line data is denoted by C<L:> and uses the format of two points, devided by C<E<lt>=E<gt>>.  Only one piece of data is allowed per line.  Syntax errors are ignored.

Example File:

 P: 0,0
 P: 1,1
 L: 0,0 <=> 1,1

=head1 METHODS

The following methods are provided:

=over 4

=item my $input = PuzzleSolver::IO::Read -E<gt> new();

This method creates and returns an input object to be used for retrieving puzzle data.

=cut

sub new {
    my $that = shift;
    my $this = ref ( $that ) || $that;

    return bless { }, $this;
}

=item my @points = @{ $input -E<gt> read_points_from_file( $file ) };

This method reads C<$file> and takes point coordinates from it, returning point objects.

=cut

sub read_points_from_file {
    my $self = shift;
    my $file = shift;

    my @file = read_file( $file );
    my @points;

    foreach my $line ( @file ) {
        my ( $x, $y ) = $line =~ m/^P: (\d+),(\d+)$/;
        if ( defined $x and defined $y ) {
            push @points, PuzzleSolver::Geometry::Point -> new(
                x => int $x, y => int $y );
        }
    }

    return \@points;
}

=item @lines = @{ $input -E<gt> read_lines_from_file( $file ) };

This method reads C<$file> and takes line endpoints from it, returning line objects.

=cut

sub read_lines_from_file {
    my $self = shift;
    my $file = shift;

    my @file = read_file( $file );
    my @lines;

    foreach my $line ( @file ) {
        my ( $x1, $y1, $x2, $y2 )
            = $line =~ m/^L: (\d+),(\d+) <=> (\d+),(\d+)$/;
        if ( defined $x1 and defined $x2
               and defined $y1 and defined $y2 ) {
            push @lines, PuzzleSolver::Geometry::Line -> new(
                p1 => PuzzleSolver::Geometry::Point -> new(
                    x => $x1, y => $y1 ),
                p2 => PuzzleSolver::Geometry::Point -> new(
                    x => $x2, y => $y2 ),
                );
        }
    }

    return \@lines;
}

=item $piece = $input -E<gt> read_snafooz_piece_from_file( $file );

This method retrieves snafooz piece info from a text file and returns a snafooz piece object.

=cut

sub read_snafooz_piece_from_file {
    my $self = shift;
    my $file = shift;

    my @file = read_file( $file );
    my @sides;

    {
        my ( @top, @right, @bottom, @left );
        
        @top = $file[0] =~ m/([0,1])/g;
        @bottom = $file[@file-1] =~ m/([0,1])/g;

        foreach my $line ( @file ) {
            push @left, $line =~ m/^[^0,1]*([0,1])/;
            push @right, $line =~ m/([0,1])[^0,1]$/;
        }

        push @sides, PuzzleSolver::Snafooz::Side -> new(
            side => join "", @top );
        push @sides, PuzzleSolver::Snafooz::Side -> new(
            side => join "", @right );
        push @sides, PuzzleSolver::Snafooz::Side -> new(
            side => join "", reverse @bottom );
        push @sides, PuzzleSolver::Snafooz::Side -> new(
            side => join "", reverse @left );
    }

    return PuzzleSolver::Snafooz::Piece -> new(
        sides => \@sides );
}

=item @pieces = @{ $input -E<gt> read_snafooz_pieces_from_dir( $dir );

This method reads a group of pieces out of a directory.  See read_snafooz_piece_from_file().  There is no guarenteed order for the pieces to be read.

=cut

sub read_snafooz_pieces_from_dir {
    my $self = shift;
    my $dir = shift;

    my @c = grep { /\.txt$/ } read_dir( $dir );
    my @pieces;
    foreach my $i ( 0 .. @c-1 ) {
        push @pieces, $self -> read_snafooz_piece_from_file(
            "$dir/$c[$i]" );
        $pieces[$i] -> serial( $i );
    }
    return \@pieces;
}


=item $container = $input -E<gt> read_node_container_from_file( $file );

This method retrueves node information from a text file and returns a L<node container|PuzzleSolver::Graph::Container> containing the specified nodes.

=cut

sub read_node_container_from_file {
    my $self = shift;
    my $file = shift;

    my @file = read_file( $file );
    my $container = PuzzleSolver::Graph::Container -> new();

    my ( $count ) = $file[0] =~ m/s: (\d+)/;

    foreach ( 1 .. $count )
        { $container -> add() }

    foreach my $line ( @file ) {
        my ( $from, $to, $weight )
            = $line =~ m/c: (\d+) => (\d+), (\d+)/;
        if ( $weight ) {
            $container -> node($from) -> con(
                node => $container -> node($to),
                weight => $weight );
        }
    }

    return $container;
}

=back

=cut

1;
