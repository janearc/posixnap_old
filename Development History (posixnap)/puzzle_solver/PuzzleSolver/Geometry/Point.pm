package PuzzleSolver::Geometry::Point;

use strict;
use warnings;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Geometry::Point - A simple 2D point

=head1 SYNOPSIS

 use PuzzleSolver::Geometry::Point;

 my $p = PuzzleSolver::Geometry::Point -> new( x => 3, y => -5 );

 print $p -> X( 7 ), "\n";

=head1 ABSTRACT

This module is an abstraction of a point in 2-dimensional space.  It holds data for x and y coordinates.

=head1 METHODS

The following methods are provided:

=over 4

=item my $point = PuzzleSolver::Point -E<gt> new( %arguments );

This method creates and returns a point.  %arguments is an optional hash containing the initial x and y coordinates.  Arguments go as such:

C<new( x =E<gt> 4, y =E<gt> 2 )>

The default x and y value is C<0>.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;
    my $x = $args{ x } || 0;
    my $y = $args{ y } || 0;

    return bless {
        objects =>
            { x => $x,
              y => $y,
            },
    }, $this;
}

=item $point -E<gt> X( $int );

This method returns the current x value.  Optionally, it will also set this value.  When setting the value, this returns the new given value.

=cut

sub X {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {x} = shift;
    }
    return $self -> {objects} -> {x};
}

=item $point -E<gt> Y( $int );

This is identical to C<X()> but functions on the y value.

=cut

sub Y {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {y} = shift;
    }
    return $self -> {objects} -> {y};
}

=item $point -E<gt> is_equal ( $other_point );

This method takes a point and compares it to the named point.  This returns true if the points are the same, ie. they have the same x and y values.

=cut

sub is_equal {
    my $self = shift;
    my $p = shift;

    return $self -> X() == $p -> X()
        and $self -> Y() == $p -> Y();
}

=back

=cut

1
