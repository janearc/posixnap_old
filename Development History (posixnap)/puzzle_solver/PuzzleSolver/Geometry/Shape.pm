package PuzzleSolver::Geometry::Shape;

use strict;
use warnings;
use PuzzleSolver::Geometry::Line;
use PuzzleSolver::Geometry::Point;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Geometry::Shape - A coordinate based 2D shape object

=head1 SYNOPSIS

 use PuzzleSolver::Geometry::Shape;

 my $shape = PuzzleSolver::Geometry::Shape -> new();

 my @lines = @{ $shape -> lines() };
 my @bounds = @{ $shape -> bounds() };

 $shape -> containes(
    PuzzleSolver::Geometry::Point -> new() )
    ? print "This shape contains this point\n"
    : print "This shape doens't contain this point\n";

=head1 ABSTRACT

This module is an abstraction of a closed 2-dimensional shape, or polygon.  It is based on a series of L<points|PuzzleSolver::Geometry::Point> or L<lines|PuzzleSolver::Geometry::Line>.  It will only accept points or lines representing a closed shape, but lines constructing the shape may intersect and overlap.  This module also contains several methods for working with this shape object, including bounds checking operations.

=head1 METHODS

The following methods are provided:

=over 4

=item my $shape = PuzzleSolver::Geometry::Shape -E<gt> new ( %arguments );

This method creates and returns a shape object.  This shape is represented by a series of points, given in connect-the--dot order.  %arguments is an optional hash that may be used to specify the initial points.  These can be specified in two ways, either by an arrayref of points, or an arrayref of lines.  Specifying both may produce unexpected results.

C<%arguments = ( 'points' =E<gt> [ $p1, $p2, ... , $pn ] );>

or

C<%arguments = ( 'lines' =E<gt> [ $l1, $l2, ... , $ln ] );>

Note: If points are given, the first and last point should the the same in order to represent a closed figure.  Lines are expected to form a closed shape as well.

By default this creates a square from (0,0) to (1,1) if no data is given.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $lines;

    if ( $args{ points } ) {
        $lines = _points_to_lines( $args{ points } );
    } elsif ( $args{ lines } ) {
        $lines = $args{ lines };
    } else {
        my $points = [
            PuzzleSolver::Geometry::Point -> new(
                x => 0, y => 0 ),
            PuzzleSolver::Geometry::Point -> new(
                x => 1, y => 0 ),
            PuzzleSolver::Geometry::Point -> new(
                x => 1, y => 1 ),
            PuzzleSolver::Geometry::Point -> new(
                x => 0, y => 1 ) ];

        $lines = _points_to_lines( $points );
    }

    _valid_shape( $lines )
        || die "given shape is not valid\n";

    return bless {
        objects => {
            lines => $lines,
        },
    }, $this;
}

=item $bounds = $shape -E<gt> bounds();

This method returns an arrayref of two points, representing the outside bounds of the shape.  These points could be used to draw a rectangle encompasing the entire shape.  The first point is for the bottom left corner and the second for the top right.

=cut

sub bounds {
    my $self = shift;

    my ( $min_x, $min_y, $max_x, $max_y );

    foreach my $line ( @{ $self -> {objects} -> {lines} } ) {
        my $p = $line -> p1();
        
        if (! defined $min_x )
            { $min_x = $p -> X(); $max_x = $p -> X() }
        elsif ( $p -> X() < $min_x )
            { $min_x = $p -> X() }
        elsif ( $p -> X() > $max_x )
            { $max_x = $p -> X() }

        if (! defined $min_y )
            { $min_y = $p -> Y(); $max_y = $p -> Y() }
        elsif ( $p -> Y() < $min_y )
            { $min_y = $p -> Y() }
        elsif ( $p -> Y() > $max_y )
            { $max_y = $p -> Y() }
    }

    return [
        PuzzleSolver::Geometry::Point -> new(
            x => $min_x, y => $min_y ),
        PuzzleSolver::Geometry::Point -> new(
            x => $max_x, y => $max_y ),
    ];
}

=item my $area = $shape -E<gt> area();

This method returns the area of the polygon.  This value can be negative depending on the orrientation of the points.

=cut

sub area {
    my $self = shift;

    my @p = map { $_ -> p1() }
        @{ $self -> {objects} -> {lines} };
    
    my $area = 0;

    foreach my $i ( 0 .. @p-2 ) {
        $area += ( ( $p[$i] -> X() * $p[$i+1] -> Y() )
            - ( $p[$i+1] -> X() * $p[$i] -> Y() ) );
    }

    return $area / 2;
}

=item $shape -E<gt> lines( @lines );

This method returns an arrayref containing the lines making up this shape in the order in which they connect.  Optionally, it will also set this value when given an array of lines.

=cut

sub lines {
    my $self = shift;
    if ( @_ ) {
        _valid_shape( \@_ )
            || die "given shape is not valid\n";
        $self -> {objects} -> {lines} = \@_;
    }

    return $self -> {objects} -> {lines};
}

=item $shape -E<gt> points( @points );

This method is similar to C<lines()> but enacts on the vertices of this shape, not the lines themselves.

=cut

sub points {
    my $self = shift;
    if ( @_ ) {
        my $lines = _points_to_sides( \@_ );
        _valid_shape( $lines )
            || die "given shape is not valid\n";
        $self -> {objects} -> {lines} = $lines;
    }

    return _lines_to_points( $self -> {objects} -> {lines} );
}

=item $shape -E<gt> contains( $point );

This method takes a point and determines whether the point exists within the bounds of the shape.  If so, this returns true, otherwise undef.

=cut

sub contains {
    my $self = shift;

    my $p = shift;

    my $bounds = $self -> bounds();

    # if the point is out of bounds, don't need
    # to test any farther
    return if ( $p -> X() < $bounds -> [0] -> X()
            or $p -> Y() < $bounds -> [0] -> Y()
            or $p -> X() > $bounds -> [1] -> X()
            or $p -> Y() > $bounds -> [1] -> Y() );

    # create a line starting at the test point
    # and extending outside the bounds of this shape
    my $tl = PuzzleSolver::Geometry::Line -> new(
        p1 => $p,
        p2 => PuzzleSolver::Geometry::Point -> new(
            x => $bounds -> [1] -> X() + 1 ) );

    # count the number of times this new line
    # intersects with the lines creating this shape
    my $ints = 0;
    foreach my $l ( @{ $self -> lines() } )
        { $ints++ if $tl -> intersect( $l ) }

    # if there is an odd number of intersections,
    # the point is inside the shape
    if ( $ints % 2 > 0 ) {
        return 1;
    # if not, the point is most likely outside
    # of the shape... but there is one exception
    } else {
        # if the test line begins at, or goes
        # directly through a vertex of the
        # polygon, it was not detected above.
        foreach my $point ( @{ $self -> points() } ) {
            return 1
                if $p -> is_equal( $point );
        }

        # all else failed, this point is outside
        return;
    }
}

=item $shape -E<gt> is_equal( $other_shape );

This method takes a shape and compares it to the given shape.  This returns true if both shapes are the same, ie. they have the same coordinates.

=cut

sub is_equal {
    my $self = shift;
    my $s = shift;

    if ( scalar @{ $self -> {objects} -> {lines} }
        == scalar @{ $s -> {objects} -> {lines} } ) {

        foreach my $i ( 0 .. @{ $self -> {objects} -> {lines} } - 1 ) {
            return
                unless $self -> {objects} -> {lines} -> [$i] -> is_equal(
                    $s -> {objects} -> {lines} -> [$i] );
        }
    } else {
        return;
    }

    return 1;
}

=back

=cut

##
# This method creates a series of lines
# given a list of points
##

sub _points_to_lines {
    my @points = @{ shift() };
    my @lines;
    foreach my $i ( 0 .. @points-1 ) {
        push @lines, PuzzleSolver::Geometry::Line -> new(
            p1 => $points[$i], p2 => $points[($i+1)%@points] );
    }

    return \@lines;
}    

##
# This method creates a series of points
# given a list of lines
##

sub _lines_to_points {
    my @lines = @{ shift() };
    my @points;
    foreach my $l ( @lines ) {
        push @points, $l -> p1();
    }

    return \@points;
}

##
# This method looks at the given list
# of lines and determines if they
# represent a valid closed shape
##

sub _valid_shape {
    my @lines = @{ shift() };

    foreach my $i ( 0 .. @lines-1 ) {
        return
            unless $lines[$i] -> p2() -> is_equal(
                $lines[($i+1)%@lines] -> p1() );
    }

    return 1;
}

1;
