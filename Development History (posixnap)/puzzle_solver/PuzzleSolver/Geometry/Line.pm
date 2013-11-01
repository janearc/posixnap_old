package PuzzleSolver::Geometry::Line;

use strict;
use warnings;
use PuzzleSolver::Geometry::Point;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Geometry::Line - A simple 2D line

=head1 SYNOPSIS

 use Puzzle::Solver::Geometry::Point;
 use PuzzleSolver::Geometry::Line;

 my $p1 = Puzzle::Solver::Geometry::Point -> new(
    x => 2, y => 3 );
 my $p2 = Puzzle::Solver::Geometry::Point -> new(
    x => 13, y => 5 );

 my $line = PuzzleSolver::Geometry::Line -> new(
    p1 => $p1, ps => $p2 );
 
 print $line -> slope(), "\n";

=head1 ABSTRACT

This module is an abstraction of a simple line.  It is based on L<PuzzleSolver::Geometry::Point|PuzzleSolver::GEometry::Point> end points.  It also contains several methods which return information about the line.

=head1 METHODS

The following methods are provided:

=over 4

=item my $line = PuzzleSolver::Geometry::Line -E<gt> new( %arguments );

This method creates and returns a line object.  %arguments is an optional hash containing the initial end points for the line.  Arguments are as such:

C<new( p1 =E<gt> $p1, p2 =E<gt> $p2 )>

The default values are points with coordinates (0, 0) and (1, 1).

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;
    my $p1 = $args{ p1 }
        || PuzzleSolver::Geometry::Point -> new();
    my $p2 = $args{ p2 }
        || PuzzleSolver::Geometry::Point -> new(
            x => 1, y => 1 );

    return bless {
        objects =>
            { p1 => $p1,
              p2 => $p2,
            },
    }, $this;
}

=item $line -E<gt> p1( $point );

This method returns the current point stored as the first end point.  Optionally, this will also set this value when passed a L<point|PuzzleSolver::Geometry::Point>.  When setting this value, this returns the new given value.

=cut

sub p1 {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {p1} = shift;
    }
    return $self -> {objects} -> {p1};
}

=item $line -E<gt> p2( $point );

This method is identical to C<p1()> but functions on the second endpoint.

=cut

sub p2 {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {p2} = shift;
    }
    return $self -> {objects} -> {p2};
}

=item my $slope = $line -E<gt> slope();

This method returns the slope of the line.  In the case that this function needs to devide by 0 (vertical line), this method will return 9999.

=cut

sub slope {
    my $self = shift;
    my ( $p1, $p2, $dx, $dy );

    $p1 = $self -> {objects} -> {p1};
    $p2 = $self -> {objects} -> {p2};

    $dx = $p2 -> X() - $p1 -> X();
    $dy = $p2 -> Y() - $p1 -> Y();

    if ( $dx == 0 ) {
        return 9999;
    } else {
        return $dy / $dx;
    }
}

=item $line -E<gt> intersect ( $other_line );

This method takes a line object and determines if the line intersects the given line.  This returns true if the lines do infact intersect.

=cut

sub intersect {
    my $self = shift;
    my $l = shift;

    my @p = (
        $self -> p1(),
        $self -> p2(),
        $l -> p1(),
        $l -> p2(),
    );

    my $b1 = ( _clockwise( $p[0], $p[1], $p[2] )
        xor _clockwise( $p[0], $p[1], $p[3] ) );

    my $b2 = ( _clockwise( $p[3], $p[2], $p[0] )
        xor _clockwise( $p[3], $p[2], $p[1] ) );

    return ( $b1 and $b2 );
}

=item $line -E<gt> is_equal( $other_line );

This method takes a line and compares it to the named line.  This returns true if the lines are the same, ie. they have the same end points.

=cut

sub is_equal {
    my $self = shift;
    my $l = shift;

    return $self -> p1() -> is_equal( $l -> p1() )
        and $self -> p2() -> is_equal( $l -> p2() );
}

=back

=cut

##
# This method takes three points and
# determines if these points exist
# in clockwise mannar
##

sub _clockwise {
    my ( $p1, $p2, $p3 ) = @_;

    my $dx1 = $p3 -> X() - $p1 -> X();
    my $dx2 = $p2 -> X() - $p1 -> X();

    my $dy1 = $p3 -> Y() - $p1 -> Y();
    my $dy2 = $p2 -> Y() - $p1 -> Y();

    return ($dx1 * $dy2) >= ($dx2 * $dy1);
}   

1;
