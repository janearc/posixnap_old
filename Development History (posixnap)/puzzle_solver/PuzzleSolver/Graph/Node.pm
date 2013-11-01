package PuzzleSolver::Graph::Node;

use strict;
use warnings;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Graph::Node - A graph node

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Graph::Node;

 my $node = PuzzleSolver::Graph::Node -> new();
 my $node2 = PuzzleSolver::Graph::Node -> new(
    serial => 5 );

 my $s = $node -> serial();

 $node -> con( node => $node2, weight => -12 );

 my @c = @{ $node -> connections() };

=head1 ABSTRACT

This is a simple graph node, designed to connect with other graph nodes and is capable of maintaining weights on each node connection.

=head1 METHODS

The following methods are provided:

=over 4

=item my $node = PuzzleSolver::Graph::Node -E<gt> new( %args );

This method creates and returns a graph node.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $serial;

    $serial = int rand 10000
        unless ( defined( $serial = $args{serial} ) );

    return bless {
        objects => {
            serial => $serial,
            conns => [ ],
        }
    }, $this;
}

=item $serial = $node -E<gt> serial( $serial );

This method returns the serial of the node.  Optionally, this will also set the C<$serial> value when passed an argument.  A serial can be aything, excluding null.

=cut

sub serial {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {serial} = shift;
    }
    return $self -> {objects} -> {serial};
}

=item $node -E<gt> con( %args );

This method connects a node to another node.  C<%args> is in the form:

 { node => $n, weight => $w }

C<node> is the node to connect to.

C<weight> is an optional weight to be put on the connection.  If not given, this value is 1.

=cut

sub con {
    my $self = shift;

    my %args = @_;

    my $node = $args{node} || die;
    my $weight = $args{weight} || 1;

    push @{ $self -> {objects} -> {conns} },
        { node => $node, weight => $weight };
}

=item @c = @{ $node -E<gt> connections() };

This method returns all stored connections.

=cut

sub connections {
    my $self = shift;
    return $self -> {objects} -> {conns};
}

=item $node -E<gt> is_equal( $other_node );

This method returns true of C<$node> is equal to C<$other_node>.  It does this by comparing the serials, the number of connections, and weights.

=cut

sub is_equal {
    my $self = shift;
    my $n = shift;

    return
        unless
            ( $n -> serial() eq $self -> serial() );

    return
        unless
            ( @{ $n -> connections() } == @{ $self -> connections() } );

    foreach my $i ( 0 .. @{ $self -> connections() }-1 ) {
        return
            unless $self -> {objects} -> {conns} -> [$i] -> {weight}
                == $n -> {objects} -> {conns} -> [$i] -> {weight};
    }

    return 1;
}

=back

=cut

1;
