#!/usr/bin/perl -w

# number of games to play
use constant GAMES => 100;

# board configuration
use constant STONES => 3;
use constant CUPS => 6;

use strict;
use warnings;

use Mancala::AI::Handful;
use Mancala::Board;
use Mancala::Board::Traverser::Classic;
use Mancala::Player::Machine;
use Mancala::Turn;

# this will be the ai we attempt to learn
# through bayes classification
my $handful_ai = Mancala::AI::Handful -> new();

# create an array of players
my @players = (
    Mancala::Player::Machine -> new( 'AI' => 'Mancala::AI::Random' ),
    Mancala::Player::Machine -> new(
        'AI' => 'Mancala::AI::Learning::Helpers::NaiveShell',
        agent_id => 2, piggyback => $handful_ai ),
);

foreach ( 1 .. GAMES ) {
    print "Running Game $_\n";
    run_game();
}

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
        players => \@players, board => \$board, quiet => 1 );

    # run all the turns
    while ( $turn -> next() ) { };

    # and display the final score
    $turn -> end();
}
