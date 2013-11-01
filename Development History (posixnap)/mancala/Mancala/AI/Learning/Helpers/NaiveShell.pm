package Mancala::AI::Learning::Helpers::NaiveShell;

use strict;
use warnings;
use Mancala::DB::Instances;
use Mancala::AI::Learning::Naive;
use Mancala::AI::Learning::Helpers::Simple;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::AI::Learning::Helpers::Simple/;

sub new {
    my $that = shift;
    my $self = Mancala::AI::Learning::Helpers::Simple::new(
        $that, @_, agent => Mancala::DB::Instances -> new() );

    $self -> {objects} -> {base} =
        Mancala::AI::Learning::Naive -> new(
            agent_id => $self -> {objects} -> {agent_id} );

    return $self;
}

sub decide {
    my $self = shift;
    my $board = shift
        || die "\$board_ref must be supplied\n";

    my $player = shift
        || die "\$player must be supplied\n";

    _test_boardref( $board );
    _test_player( $player );

    my $agent = $self -> {objects} -> {agent};
    my $agent_id = $self -> {objects} -> {agent_id};
    my $piggyback = $self -> {objects} -> {piggyback};
    
    # generate storable board
    my %cups = %{ $agent -> board_to_instance(
        $board, $player ) };

    my $choice_cup = $piggyback -> decide( $board, $player );

    my $offset = $agent -> cup_offset(
        $board, $player, $choice_cup );

    $agent -> add( $agent_id, $offset => %cups );

    return $choice_cup;
}

1;
