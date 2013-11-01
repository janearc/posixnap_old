package Mancala::AI::Learning::Temporal;

use strict;
use warnings;
use Mancala::AI::Learning::Simple;
use Mancala::DB::Policy;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;
use Clone qw/clone/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::AI::Learning::Simple/;

sub new {
    my $that = shift;
    
    my $self = Mancala::AI::Learning::Simple::new(
        $that, @_, agent => Mancala::DB::Policy -> new() );

    return $self;
}

sub decide {
    my $self = shift;
    my $boardref = shift;
    my $player = shift;

    my $agent = $self -> {objects} -> {agent};
    my $agent_id = $self -> {objects} -> {agent_id};

    my $instance = $agent -> encode_instance(
        $agent -> board_to_instance( $boardref, $player ) );
    my @inst_array = map { $instance -> {$_} }
        sort { $a <=> $b }
            keys %{ $instance };

    return $agent -> offset_cup(
        $boardref, $player, $agent -> get(
            $agent_id, \@inst_array ) );
}

sub ranking {
    die "Temporal does not supply a ranking... yet.\n";
}

sub value {
    my $self = shift;
    my $boardref = shift;
    my $player = shift;

    _test_boardref( $boardref );
    _test_player( $player );

    # variables for value computation
    my $agent = $self -> {objects} -> {agent};
    my $agent_id = $self -> {objects} -> {agent_id};
    my $traverser = $player -> traverser();

    # copy the board
    my $temp_board = clone( $boardref );

    # store current player score
    my $current_score = ${ $boardref } -> sides( $player ) -> goal_cup() -> stones();

    # retrieve move from database
    my $instance = $agent -> encode_instance(
        $agent -> board_to_instance( $boardref, $player ) );
    my @inst_array = map { $instance -> {$_} }
        sort { $a <=> $b }
            keys %{ $instance };
    my $move_offset = $agent -> get( 
        $agent_id, \@inst_array );

    # debug
    # print "@inst_array\n";
    # print "$move_offset\n";

    # calculate cup from offset
    my $cup = $agent -> offset_cup( $temp_board, $player, $move_offset );

    # if the move is not valid, the value is immediately 0
    return [ 0, $temp_board ]
        unless $traverser -> validate( $cup, $player, $boardref );

    # do move on $temp_board
    my $continue = $traverser -> move( $cup, $player );
    my $end = $traverser -> end( $temp_board );

    # calculate score difference
    my $gain =  
        ${ $temp_board } -> sides( $player ) -> goal_cup() -> stones()
            - $current_score;

    # return the value
    #  recurse if necessary
    if ( $continue and not $end ) {
        my $ret = $self -> value( $temp_board, $player );
        return [ $gain + $ret -> [0], $ret -> [1] ];
    } else {
        return [ $gain, $temp_board ];
    }
}

1;
