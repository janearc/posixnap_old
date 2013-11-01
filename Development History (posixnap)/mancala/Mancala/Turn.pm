package Mancala::Turn;

use strict;
use warnings;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;
use Mancala::Display::ASCII;

# throw this in to make it easier
our $display;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $players = $args{players}
        || die "Turn::new must take players\n";

    my $board = $args{board}
        || die "Turn::new must take a board object\n";

    my $quiet = $args{quiet};

    foreach ( @{ $players } ) {
        _test_player( $_ );
    }

    _test_boardref( $board );

    $display = Mancala::Display::ASCII -> new();

    bless {
        objects => {
            players => $players,
            board => $board,
            turn => 0,
            quiet => $quiet,
        },
    }, $this;
}

sub next {
    my $self = shift;

    my $board = $self -> {objects} -> {board};
    my $turn = $self -> {objects} -> {turn};
    my @players = @{ $self -> {objects} -> {players } };
    my $quiet = $self -> {objects} -> {quiet};

    # display the board
    $display -> display_board( $board )
        unless $quiet;

    # end the game when its time
    return if $players[0] -> traverser() -> end( $board );

    # start the turn
    print $players[$turn] -> name(), "'s turn...\n"
        unless $quiet;
    while ( $players[$turn] -> traverser() -> move(
            $players[$turn] -> request_choice( $board ), $players[$turn] ) ) {
        return if $players[0] -> traverser -> end( $board );
        print $players[$turn] -> name(), " gets to go again...\n"
            unless $quiet;
    }

    $turn++;
    $turn %= @players;
    $self -> {objects} -> {turn} = $turn;

    return 1;
}

sub end {
    my $self = shift;
    my $board = $self -> {objects} -> {board};
    my $quiet = $self -> {objects} -> {quiet};

    print "\nGAME OVER\n"
        unless $quiet;
    $display -> display_final_score( $board )
        unless $quiet;

    return 1;
}

1;
