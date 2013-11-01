package PuzzleSolver::Snafooz::Side;

use strict;
use warnings;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Snafooz::Side - A side to a snafooz puzzle piece

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Snafooz::Side;
 
 my $side = PuzzleSolver::Snafooz::Side -> new(
    side => "110011" );
 
 my $side2 = PuzzleSolver::Snafooz::Side -> new(
    side => "001100" );
 
 if ( $side -> fit( $side2 ) )
    print "These two sides fit together\n";

=head1 ABSTRACT

A side of a Snafooz puzzle piece is simply an abstraction of a bitvector, usually 6 bits in length.  This bit vector represents an edge of a puzzle piece in a grid system.  1 bits refer to solid pieces of the edge, 0 refers to squars cut out of the edge.

This object also contains methods for testing sides against eachother for a fit.  A side fits with another side if bits from each vector are not both 1 (ie. (0,1), (1,0), (0,0)).

=head1 METHODS

The following methods are provided:

=over 4

=item $side = PuzzleSolver::Snafooz::Side -E<gt> new( %arguments );

This method creates and returns a Snafooz side.  %arguments is a hash containing the value this side will represent.  Arguments go as such:

C<new( side =E<gt> "010101", serial =E<gt> 5 )>

C<side> is a string of 6 [0|1] values representing the side.  This is required.

C<serial>  is a serial number of this piece.  If not given, a random one is generated.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;
    
    my ( @side, $serial );

    if ( $args{side} ) {
        @side = $args{side} =~
            m/([0,1])/g;
        die "invalid side argument"
            unless @side;
    } else {
        die "'side' argument must be specified";
    }

    unless ( $serial = $args{serial} )
        { $serial = int rand 1000 }

    return bless {
        objects => {
            side => \@side,
            serial => $serial,
            connection => undef,
        },
    }, $this;

}

=item $serial = $side -E<gt> serial( $serial );

This method returns the unique serial number of this side.  Optionally, this method also sets the serial of this side when given a value.

=cut

sub serial {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {serial} = shift;
    }
    return $self -> {objects} -> {serial};
}

=item $side -E<gt> rev();

This method reverses the piece.  This means that a piece equal to C<010101> would become C<101010>.  Performing this operation a second time returns the side to the original state.

=cut

sub rev {
    my $self = shift;

    $self -> {objects} -> {side}
        = [ reverse @{ $self -> {objects} -> {side} } ];
}

=item $bool = $side -E<gt> fit( $other_side );

This method determines if two sides successfully fit together.  This returns true if the sides fit.  Note: This method tests for any fit, not necessarily a tight fit.  This means that two sides, C<010100> and C<001010> will infact fit together.

=cut

sub fit {
    my $self = shift;

    my $s = shift;

    die "Side -> fit(): \$side argument must be given\n"
        unless $s;

    die "Side -> fit(): the given side is not of the same size\n"
        unless ( scalar @{ $s -> {objects} -> {side} }
            == scalar @{ $self -> {objects} -> {side} } );

    my @my_side = @{ $self -> {objects} -> {side} };
    my @other_side = @{ $s -> {objects} -> {side}};

    foreach my $i ( 0, @my_side-1 ) {
        return if $my_side[$i] and $other_side[$i];
    }

    foreach my $i ( 1 .. @my_side-2 ) {
        return unless $my_side[$i] xor $other_side[$i];
    }

    return 1;
}

=item $s = $side -E<gt> connect( $other_side );

This method registeres a connection between two fitting sides.  When called with an argument, a connection is set or overwritten.  This also returns a side if a connection is already established.  Each side can connect only to one other side and all connections are bilateral.

=cut

sub connect {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {connection} = shift();
        $self -> {objects} -> {connection}
            -> {objects} -> {connection} = $self;
    }
    return $self -> {objects} -> {connection};
}

=item $side -E<gt> break_connection();

This method breaks a connection if one exists.  Otherwise, nothing is done.

=cut

sub break_connection {
    shift() -> {objects} -> {connection} = undef;
    return 1;
}

=item $bool = $side -E<gt> reverse_fit( $other_Side );

This method is like C<fit()> but referses the data in C<$side> before testing the fit.

=cut

sub reverse_fit {
    my $self = shift;

    my $s = shift;

    my $new_side = PuzzleSolver::Snafooz::Side -> new(
        side => join "", reverse @{ $self -> {objects} -> {side} } );

    return $new_side -> fit( $s );
}

=item $bool = $side -E<gt> is_equal( $other_side );

This method takes a side and compares it to the named side.  This returns true if the sides are the same, ie. they have the same bit information in the same order.

=cut

sub is_equal {
    my $self = shift;
    my $s = shift;

    foreach my $i ( 0 .. @{ $self -> {objects} -> {side} }-1 ) {
        return unless
            $self -> {objects} -> {side} -> [$i]
                == $s -> {objects} -> {side} -> [$i];
    }

    return 1;
}

=back

=cut

1;
