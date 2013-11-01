package Mancala::Board::Traverser::Classic;

use strict;
use warnings;
use Data::Dumper;
use Mancala::Board qw/:checks/;
use Mancala::Board::Traverser;
use Mancala::Cups::Simple qw/:checks/;
use Mancala::Player::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::Board::Traverser/;

=head1 NAME

Mancala::Board::Traverser - A bord traversing object

=head1 SYNOPSIS

 # create a traverser object and use it
 use Mancala::Board::Traverser::Classic;

 my $traverser = Mancala::Board::Traverser::Classic -> new();
 $traverser -> move( $cup, $player );

=head1 ABSTRACT

This traverser manipulates the board according to simple classic Mancala rules.  Players each own a side of the board on which they can chose cups.  When a cup is chosen, all stones are removed and put in hand.  Play goes as such:

  For each cup:
    If cup is a normal board cup, drop one stone.
    If cup is C<$player>'s goal, drop one stone.
    If cup is a goal but not C<$player>'s goal, skip.
  If last stone is dropped:
    In a board cup previously containing stones, take all stones and continue
    In C<$player>'s goal, begin turn again from begining.
    In a previously empty cup, end turn.

A valid move has these properties:
   1. Has stones
   2. Is not a goal
   3. Is on player's side
   4. Is on any side if player's side is empty

See L<Mancala::Board::Traverser>.

=cut

sub move {
    my $self = shift;

    my $cup = shift;
    my $player = shift;

    _test_cup( $cup );
    _test_player( $player );

    my $stones = $cup -> empty();

    # debugging
    # print "chosing cup with stones: $stones\n";

    while ( $stones ) {
        $cup = $cup -> next();
        if ( $cup -> is_goal ) {
            if ( $cup -> owner() -> id() == $player -> id() ) {
                $cup -> inc();
                $stones--;
                #print "dropping 1 in ", ref $cup, "\n";

                unless ( $stones ) {
                    return 1;
                }
            }
            # else, do nothing
        } else {
            $cup -> inc();
            $stones--;
            #print "dropping 1 in ", ref $cup, "\n";

            if ( $stones < 1 and $cup -> stones() > 1 ) {
                #print "out of stones...";
                $stones = $cup -> empty();
                #print "picking up $stones\n";
            }
        }
    }
}

sub end {
    my $self = shift;

    my $board = shift
        || "\$board_ref must be supplied\n";

    _test_boardref( $board );

    foreach my $side ( @{ ${ $board } -> sides() } ) {
        return undef
            unless $side -> is_empty()
    }

    return 1;
}

sub validate {
    my $self = shift;

    my $cup = shift
        || die "must provide \$cup\n";

    my $player = shift
        || die "must provide \$player\n";

    my $board_ref = shift
        || die "must provide \$board_ref\n";

    _test_cup( $cup );
    _test_player( $player );
    _test_boardref( $board_ref );

    # cup cannot be empty or goal
    if ( $cup -> stones() < 1
        or $cup -> is_goal() )
        { return undef }
    
    # if oned by $player, good
    if ( $cup -> owner() -> id() == $player -> id() )
            { return 1 }

    # test if player's side is empty
    # XXX: this falls into an infinite loop if
    # $player isn't on the board
    my $side = ${ $board_ref } -> sides( $player );
    #my $side = ${ $board_ref } -> sides(0);

    #while ( $side -> owner() -> id() != $player -> id() )
    #    { $side = $side -> next() }

    if ( $side -> is_empty() )
        { return 1 }

    return undef;
}

sub valid_cups {
    my $self = shift;

    my $player = shift
        || die "\$player must be supplied\n";

    my $board = shift
        || die "\$board_ref must be supplied\n";

    _test_boardref( $board );
    _test_player( $player );

    my $first_cup = ${ $board } -> sides(0) -> first_cup();

    my @valid_cups
        = $self -> validate( $first_cup, $player, $board )
            ? $first_cup
            : ( );

    my $cup = $first_cup -> next();

    until ( $cup == $first_cup ) {
        if ( $self -> validate( $cup, $player, $board ) )
            { push @valid_cups, $cup }
        $cup = $cup -> next();
    }

    return \@valid_cups;
}

1;
