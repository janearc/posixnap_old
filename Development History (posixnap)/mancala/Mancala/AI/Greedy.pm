package Mancala::AI::Greedy;

use constant STONES => 0;
use constant RANK => 0;
use constant CUP => 1;
use constant MOVES => 2;

use strict;
use warnings;
use Data::Dumper;
use Mancala::AI::Simple;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::AI::Simple/;

=head1 NAME

Mancala::AI::Greedy - A Mancala AI

=head1 SYNOPSIS

 # create a player with an AI
 use Mancala::Player::Machine;
 
 my $player = Mancala::Player::Machine -> new(
    'AI' => 'Mancala::AI::Greedy' );

=head1 ABSTRACT

This Mancala AI always choses the play yielding the greatest gain in stones.

=cut

sub decide {
    my $self = shift;

    my $ranking = $self -> ranking( @_ );

    my $cup = ${ $ranking }[0];

    foreach ( @{ $ranking } ) {
        if ( $_ -> [RANK] > $cup -> [RANK] )
            { $cup = $_ }
    }

    return $cup -> [CUP];
}

sub ranking {
    my $self = shift;

    my $tree = $self -> _generate_tree ( @_ );

    my @array = map { [ $_ -> [STONES], $_ -> [CUP] ] } @{ $tree };

    return \@array;
}

sub _generate_tree {
    my $self = shift;
    my $board = shift
        || die "requires \$board_ref\n";
    my $player = shift
        || die "requires \$player\n";

    _test_boardref( $board );
    _test_player( $player );

    my $traverser = $player -> traverser();

    my $goal_stones
        = ${ $board } -> sides( $player ) -> goal_cup() -> stones();

    my @possible_moves = @{ $traverser -> valid_cups( $player, $board ) };
    
    my @move_list = qw//;
    
    foreach my $move_index ( 0 .. @possible_moves-1 ) {
        # make a new board
        my $new_board = \${ $board } -> clone();

        # find equivelant cups on the new board
        my @new_moves = @{ $traverser -> valid_cups( $player, $new_board ) };

        my $next_move = undef;
        # take the move on the new board
        if ( $traverser -> move ( $new_moves[$move_index], $player ) ) {
            # player has another move
            $next_move = $self -> _generate_tree ( $new_board, $player );
        }
            

        my $new_goal_stones
            = ${ $new_board } -> sides( $player ) -> goal_cup() -> stones();

        # tally stones gained
        my $stones_gained = $new_goal_stones - $goal_stones;
        # if there were other moves,
        # find the move with the greatest return and add it
        if ( $next_move ) {
            my $stone_count = 0;
            foreach my $move ( @{ $next_move } ) {
                if ( $move -> [STONES] > $stone_count )
                    { $stone_count = $move -> [STONES] }
            }
            $stones_gained += $stone_count;
        }

        push @move_list, [ $stones_gained, $possible_moves[$move_index], $next_move ];
    }

    return \@move_list;
}

1;
