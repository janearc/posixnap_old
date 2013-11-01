#!/usr/bin/perl -w

use constant STONES => 3;
use constant CUPS => 6;

use strict;
use warnings;
use Data::Dumper;
use Mancala::Board;
use Mancala::Display::ASCII;
use Mancala::Board::Traverser::Classic;
use Mancala::Player::Human;
use Mancala::Player::Machine;

my $d = Mancala::Display::ASCII -> new();

my @players;
push @players, Mancala::Player::Human -> new( 'display' => $d );
push @players, Mancala::Player::Machine -> new( 'AI' => 'Mancala::AI::Greedy' );

my $board = Mancala::Board -> new(
    'players' => \@players,
    'create' => 1,
    'stones' => STONES,
    'cups' => CUPS );

# very simple turn engine
my $turn = 0;
while ( 1 ) {
    #$d -> display_board( \$board );
    end() if $players[0] -> traverser() -> end( \$board );
    print $players[$turn] -> name(), "'s turn...\n";
    while ( $players[$turn] -> traverser() -> move(
            $players[$turn] -> request_choice( \$board ), $players[$turn] ) ) {
        end() if $players[0] -> traverser() -> end( \$board );
        print $players[$turn] -> name(), " gets to go again...\n";
    }
    $turn++;
    $turn %= @players;
}

sub end {
    print "\nGAME OVER\n";
    $d -> display_final_score( \$board );
    exit;
}
