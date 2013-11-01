package PuzzleSolver::Snafooz::Piece;

use strict;
use warnings;
use PuzzleSolver::Snafooz::Side;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Snafooz::Piece - A snafooz puzzle piece

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Snafooz::Piece;

 my $piece = PuzzleSolver::Snafooz::Side -> new(
    sides => [ $s1, $s2, $s3, $s4 ], serial => 2);
 
 $piece -> rotate();
 $piece -> rev();
 my $side = $piece -> side(2);

 $piece -> fit( $other_piece );
 $piece -> is_equal( $piece );

=head1 ABSTRACT

This module is an abstraction of a Snafooz puzzle piece.  It represents a piece as a grouping of four puzzle sides, each with the ability to connect with sides of other pieces.

=head1 METHODS

The following methods are provided:

=over 4

=item $piece = PuzzleSolver::Snafooz::Piece -E<gt> new( %arguments );

This method creates and returns a Snafooz puzzle piece object.  %arguments is an optional hash containing the initial data for this puzzle piece.  Arguments are as such:

C<new( sides =E<gt> [ $s1, $s2, $s3, $s4 ], serial =E<gt> 5)>

C<sides> is a hashref containing the L<PuzzleSolver::Snafooz::Side|sides> that will represent this piece.  Sides are given starting with the top left corner and reading clockwise around the piece.  If sides are not specified, this piece will have only empty sides, ie. 000000.  Note: Sides will be reassigned serial numbers.  Any serials given to the given sides will be changed.  Do not give the same side object to two different pieces.

C<serial> is a value to be used as the serial number for this piece.  This is usually a number.  If none is given, a random number will be assigned.

=cut 

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my ( $serial, $sides );
    $sides = [];

    if ( $args{sides} ) {
        die unless @{ $args{sides} } == 4;
        $sides = $args{sides};
    } else {
        for ( 1 .. 4 ) {
            push @{ $sides },
                PuzzleSolver::Snafooz::Side -> new(
                    side => "000000" );
        }
    }

    unless ( $serial = $args{serial} )
        { $serial = int rand 1000 }

    foreach ( 0 .. 3 )
        { $sides -> [$_] -> serial( "$serial.$_" ) }

    return bless {
        objects => {
            sides => $sides,
            serial => $serial,
            rotations => 0,
            flips => 0,
        },
    }, $this;
}

=item $serial = $piece -E<gt> serial( $serial );

This method returns the unique serial number of this piece.  Optionally, this method also sets the serial of this piece when given a value.

=cut

sub serial {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {serial} = shift;
        foreach my $i ( 0 .. 3 ) {
            $self -> {objects} -> {sides} -> [$i] -> serial(
                $self -> {objects} -> {serial}.".$i" );
        }
    }
    return $self -> {objects} -> {serial};
}

=item $piece -E<gt> break_connections();

This method breaks all connections between its sides and sides belonging to other pieces.  It is a shortcut to the C<break_connection()> method found in L<PuzzleSolver::Snafooz::Side|side> objects.  See L<PuzzleSolver::Snafooz::Side>.

=cut

sub break_connections {
    my $self = shift;
    foreach my $side ( @{ $self -> {objects} -> {sides} } ) {
        $side -> break_connection();
    }
    return 1;
}

=item $piece -E<gt> rotate();

This method rotates the entire piece clockwise 90 degrees.  The actual process consists of changing the serial numbers on each side as to appear rotated clockwise.

=cut

sub rotate {
    my $self = shift;

    my @sides = @{ $self -> {objects} -> {sides} };
    my @new_sides;

    foreach my $i ( 0 .. 3 ) {
        $new_sides[$i] = $sides[($i+3)%4];
    }

    $self -> {objects} -> {sides} = \@new_sides;

    $self -> serial( $self -> serial() );

    $self -> {objects} -> {rotations} =
        ( $self -> rot_count() + 1 ) % 4;
    
    1;
}

=item $piece -E<gt> rot_count();

This method returns the number of times this piece has been rotated.

=cut

sub rot_count {
    my $self = shift;

    return $self -> {objects} -> {rotations};
}

=item $piece -E<gt> rev();

This method reverses or flips over the piece.  This has the effect of reversing every side, as well as reorienting them.  Side 0 becomes side 3 and vice versa.  This is reversable by performing the reverse operation again,

=cut

sub rev {
    my $self = shift;

    $self -> {objects} -> {sides}
        = [ reverse @{ $self -> {objects} -> {sides} } ];

    foreach my $side ( @{ $self -> {objects} -> {sides} } ) {
        $side -> rev();
    };

    $self -> {objects} -> {flips} = 
        ( $self -> rev_count() + 1 ) % 2;

    return 1;
}

=item $piece -E<gt> rev_count();

This method returns the number of times this piece has been flipped.

=cut

sub rev_count {
    my $self = shift;

    return $self -> {objects} -> {flips};
}


=item $side = $piece -E<gt> side( $index );

This method returns the side at the given C<$index>.  The index should be an integer between and including 0 and 3.

=cut

sub side {
    my $self = shift;
    my $i = int ( shift() ) % 4;

    return $self -> {objects} -> {sides} -> [$i];
}

=item @ides = @{ $piece -E<gt> sides() };

Thius method returns a reference to all sides within this piece.

=cut

sub sides {
    my $self = shift;
    return $self -> {objects} -> {sides};
}

=item $piece -E<gt> fit( $other_piece );

This method tests if the given piece connects to C<$other_piece>.  If connections are found, this returns an arrayref containing all the serial numbers of the sides it connects to.  Otherwise, this returns an empty arrayref.

The output is in the form:
 [
   [ $this_serial, $that_serial ],
   [ ..., ... ],
 ]

=cut

sub fit {
    my $self = shift;
    my $p = shift;

    my @fits;

    foreach my $side ( @{ $self -> {objects} -> {sides} } ) {
        foreach ( @{ $p -> {objects} -> {sides} } ) {
            if ( $side -> reverse_fit( $_ ) )
                { push @fits, [ $side, $_ ] }
        }
    }

    return \@fits;
}

=item $piece -E<gt> reverse_fit( $other_piece );

This method acts like C<fit()> but tests if the inverse of the piece fits.

=cut

sub reverse_fit {
    my $self = shift;
    my $p = shift;

    my @fits;

    foreach my $side ( @{ $self -> {objects} -> {sides} } ) {
        foreach ( @{ $p -> {objects} -> {sides} } ) {
            if ( $side -> fit( $_ ) )
                { push @fits, [ $side, $_ ] }
        }
    }

    return \@fits;
}

=item $bool = $piece -E<gt> is_equal( $other_piece );

This method tests if a piece is equal to another given piece.  This returns true if the pieces are the same, ie. they have equal sides.

=cut

sub is_equal {
    my $self = shift;
    my $p = shift;

    foreach my $i ( 0 .. 3 ) {
        return unless
            $self -> {objects} -> {sides} -> [$i] -> is_equal(
                $p -> {objects} -> {sides} -> [$i] );
    }

    return 1;
}

=item $piece -E<gt> to_string();

This method returns the piece in string form.  This should be identical to the pieces read from the example text files.

=cut

sub to_string {
    my $self = shift;

    my @l;

    my @s = @{ $self -> {objects} -> {sides} };

    $l[0] = join " ", @{ $s[0] -> {objects} -> {side} };

    foreach my $i ( 1 .. 4 ) {
        $l[$i] = $s[3] -> {objects} -> {side} -> [5-$i] .
            " 1 1 1 1 " .
            $s[1] -> {objects} -> {side} [$i];
    }
    
    $l[5] = join " ", reverse @{ $s[3] -> {objects} -> {side} };

    return ( join "\n", @l ) . "\n";
}

=back

=cut

1;
