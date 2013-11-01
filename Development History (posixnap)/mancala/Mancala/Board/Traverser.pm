package Mancala::Board::Traverser;

use strict;
use warnings;
use Data::Dumper;
use Exporter;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_traverser/;
%EXPORT_TAGS = (
    'checks' => [qw/_test_traverser/]
);

=head1 NAME

Mancala::Board::Traverser - A board traversing object

=head1 SYNOPSIS

 # create a traverser object and use it
 use Mancala::Board::Traverser;

 my $traverser = Mancala::Board::Traverser -> new();

 $traverser -> move( $cup, $player );

=head1 ABSTRACT

This module provides an object for traversing the mancala board.  Via the C<move()> method, it acts apon the board in some prespecified manner.  This method is provided by sub classes inheriting this object.  This object should not be used, use only its children.

See Mancala::Board::Traverser::*

=head1 METHODS

The following methods are available:

=over 4

=item $traverser = Mancala::Board::Traverser -E<gt> new( %args );

This method returns a Mancala::Board::Traverser object.  %args is a hash of initial values.  Required values are traverser specific, see subclasses for information.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args ) = @_;

    return bless {
        'objects' => {
            %args
        }
    }, $this;
}

=item $retval = $traverser -E<gt> move( $cup, $player );

This method makes a move as according to one ruleset.  Rules are specified in sup classes found in Mancala::Board::Traverser::*.

The return value is the status of the player's turn.  If true, then player is allowed to chose again, undefined otherwise.

=cut

sub move {
    return undef;
}

=item $retval = $traverser -E<gt> end( $board_ref );

This method returns true if the game is over.  This usually the case when all cups are empty but can be specfied on a rule by rule basis by the subclass.

=cut

sub end {
    return undef;
}

=item $retval = $traverser -E<gt> validate( $cup, $player, $board_ref );

This method tests if a given move is valid for this particular set of rules.  It has the same arguments as C<move()> with the adition of a L<Mancala::Board|Mancala::Board> reference.  This returns true when a move is valid.

NOTE: It is very important that C<$player> exists on C<$board_ref> or some traversers may break into an infinite loop.  This is not easy to test for.

=cut

sub validate {
    return undef;
}

=item @valid_cups = @{ $traverser -E<gt> valid_cups( $player, $board_ref ) };

This method tests every cup with C<validate()> and returns an arrayref containing every cup which is a valid move for C<$player>.  If there are no valid moves, this returns undef.

=cut

sub valid_cups {
    return undef;
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_traverser( $traverser );

This method performs a sanity check on the value C<$traverser>.  It returns true if C<$traverser> is a L<Mancala::Board::Traverser|Mancala::Board::Traverser> or compatable object.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag.

=cut

sub _test_traverser {
    my $traverser = shift;
    return 1 if ref $traverser and $traverser -> can( 'move' );
    die "\$traverser must be a traverser object\n";
}

=back

=cut

1;
