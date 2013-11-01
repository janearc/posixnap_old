#!/usr/bin/perl -w

# board configuration
use constant STONES => 3;
use constant CUPS => 6;

use strict;
use warnings;

use Mancala::Board;
use Mancala::Board::Traverser::Classic;
use Mancala::Player::Machine;
use Mancala::Turn;

# create an array of players
my @players = (
    Mancala::Player::Machine -> new( 'AI' => 'Mancala::AI::Random' ),
    Mancala::Player::Machine -> new(
        'AI' => 'Mancala::AI::Learning::Naive', agent_id => 1 );
);

run_game();

exit;

sub run_game {
    # create the board
    my $board = Mancala::Board -> new(
        'players' => \@players,
        'create' => 1,
        'stones' => STONES,
        'cups' => CUPS );

    # create the turn engine
    my $turn = Mancala::Turn -> new(
        players => \@players, board => \$board );

    # run all the turns
    while ( $turn -> next() ) { };

    # and display the final score
    $turn -> end();
}
