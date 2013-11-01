package PuzzleSolver::Graph::Container;

use strict;
use warnings;
use PuzzleSolver::Graph::Node;

=head1 NAME

PuzzleSolver::grapg::Container - A container for graph nodes

=head1 SYNOPSYS

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=item my $c = PuzzleSolver::Graph::Container -E<gt> new( %args );

This method creates and returns a graph container.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    return bless {
        objects => {
            nodes => [],
        },
    }, $this;
}

=item $c -E<gt> add( $node );

This method adds a node to the container.  If this method is called without a node, this will create a new node with a serial number equal to the index and add it.

=cut

sub add {
    my $self = shift;

    my $n;
    if ( @_ ) {
        $n = shift;
    } else {
        $n = PuzzleSolver::Graph::Node -> new(
            serial => $self -> size() );
    }

    push @{ $self -> {objects} -> {nodes} }, $n;

    1;
}

=item @nodes = @{ $c -E<gt> nodes() };

This method returns an array of all nodes in the container.

=cut

sub nodes {
    my $self = shift;
    return $self -> {objects} -> {nodes};
}

=item $node = $c -E<gt> node( $index );

This method returns the node at a given index.  This treats the node container as an array, disregarding the connections between the nodes.  This has no relation to the node serial numbers.

=cut

sub node {
    my $self = shift;
    my $i = shift;

    return $self -> {objects} -> {nodes} -> [$i];
}

=item $size = $c -> E<gt> size();

This method returns the size of the container or how many nodes are currently stored within.

=cut

sub size {
    my $self = shift;
    return scalar @{ $self -> nodes() };
}

=back

=cut

1;
