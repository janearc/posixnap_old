package Mancala::AI::Learning::Helpers::TemporalCruncher;

use strict;
use warnings;
use Mancala::AI::Learning::Temporal;
use Mancala::AI::Learning::Simple;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::AI::Learning::Simple/;

sub new {
    my $that = shift;

    my $self = Mancala::AI::Learning::Simple::new(
        $that, @_, agent => Mancala::DB::Policy -> new() );

    $self -> {objects} -> {base} =
        Mancala::AI::Learning::Temporal -> new(
            agent_id => $self -> {objects} -> {agent_id} );

    die "This AI must have a value for 'backup' (0 - 1]\n"
        unless ( $self -> {objects} -> {backup}
            and $self -> {objects} -> {backup} >= 0
            and $self -> {objects} -> {backup} < 1 );
    
    die "This AI must have a value for 'discount' (0 - 1)\n"
        unless ( $self -> {objects} -> {discount}
            and $self -> {objects} -> {discount} >= 0
            and $self -> {objects} -> {discount} <= 1 );

    return $self;
}

sub decide {
    my $self = shift;
    my $boardref = shift;
    my $player = shift;

    _test_boardref( $boardref );
    _test_player( $player );

    my $base = $self -> {objects} -> {base};

    $self -> set_best_instance( $boardref, $player );

    return $base -> decide( $boardref, $player );
}

sub set_best_instance {
    my $self = shift;
    my $board = shift;
    my $player = shift;

    _test_boardref( $board );
    _test_player( $player );

    my $agent = $self -> {objects} -> {agent};
    my $agent_id = $self -> {objects} -> {agent_id};

    my $player_id = $player -> id();

    # foreach possible move, try it and find the max gain

    my @possible_moves = @{ $player -> traverser() -> valid_cups( $player, $board ) };
    my @move_values;

    foreach my $move_index ( 0 .. @possible_moves-1 ) {
        # make a new board
        my $new_board = \${ $board } -> clone();

        # find equivelant cups on the board
        my @new_moves = @{ $player -> traverser() -> valid_cups( $player, $new_board ) };

        my $current_score = ${ $new_board } -> sides( $player ) -> goal_cup() -> stones();

        my $continue = $player -> traverser() -> move( $new_moves[$move_index], $player );
        my $done = $player -> traverser() -> end( $new_board );

        my $gain =
            ${ $new_board } -> sides( $player ) -> goal_cup() -> stones()
                - $current_score;

        # this gain will be factored in as the first sum
        # we will then start with discount_factor 1
        # if it is still our turn, keep going, else next player
        if ( $continue and not $done ) {
            # continue the player's turn
            # print "continueing\n";
            my $value_hash = $self -> calc_instance( $new_board, $player, 1 );
            $gain += $value_hash -> {$player -> id()};
        } elsif ( not $done ) {
            # print "not done yet...\n";
            # find next player and start there
            my $next_player;
            my @players = @{ ${ $new_board } -> players() };
            for ( 0 .. @players-1 ) {
                if ( $players[$_] -> id() == $player -> id() )
                    { $next_player = $players[($_+1)%@players] }
            }
            my $value_hash = $self -> calc_instance( $new_board, $next_player, 1 );
            $gain += $value_hash -> {$player -> id()} || 0;
        }

        my $move_offset = $agent -> cup_offset( $board, $player, $possible_moves[$move_index] );

        push @move_values, [ $gain, $move_offset ];
    }

    # sort out the best move index
    my $best_move = ( map { $move_values[$_] -> [1] }
        sort { $move_values[$b] -> [0] <=> $move_values[$a] -> [0] } ( 0 .. @move_values-1 )
        )[0];

    # set it in the database
    my $instance = $agent -> encode_instance(
        $agent -> board_to_instance( $board, $player ) );
    my @inst_array = map { $instance -> {$_} }
        sort { $a <=> $b }
            keys %{ $instance };

    $agent -> set( $agent_id, \@inst_array, $best_move );
}


sub calc_instance {
    my $self = shift;
    my $boardref = shift;
    my $player = shift;

    my $discount_factor = shift || 0;

    _test_boardref( $boardref );
    _test_player( $player );

    my $base = $self -> {objects} -> {base};

    my $backup = $self -> {objects} -> {backup};
    my $discount = $self -> {objects} -> {discount};

    my ( $value, $new_board ) = @{ $base -> value( $boardref, $player ) };

    $value *= ( $discount ** $discount_factor );

    # debug
    # print "calculated value for player ", $player -> name(), " is $value\n";

    # return or recurse
    if ( ( ( $discount ** $discount_factor ) <= 0.001 )
            or ( $player -> traverser() -> end( $new_board ) ) ) {
        return { $player -> id() => $value };
    } else {
        # find next player
        my $next_player;
        my @players = @{ ${ $new_board } -> players() };
        for ( 0 .. @players-1 ) {
            if ( $players[$_] -> id() == $player -> id() )
                { $next_player = $players[($_+1)%@players] }
        }

        my $ret = $self -> calc_instance( $new_board, $next_player, $discount_factor+1 );

        $ret -> { $player -> id() } += $value;
        return $ret;
    }
}

1;
