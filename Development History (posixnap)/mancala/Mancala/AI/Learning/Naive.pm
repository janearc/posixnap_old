package Mancala::AI::Learning::Naive;

use constant RANK => 0;
use constant CUP => 1;

use strict;
use warnings;
use Mancala::AI::Learning::Simple;
use Mancala::DB::Instances;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;
use Mancala::Cups::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::AI::Learning::Simple/;

sub new {
    my $that = shift;

    my $self = Mancala::AI::Learning::Simple::new(
        $that, @_, agent => Mancala::DB::Instances -> new() );

    return $self;
}

# XXX: this method must test if move is valid
# in descending order
# since it looks at all 12 cups, it will
# always find atleast 1

sub decide {
    my $self = shift;

    my $board = shift
        || die "\$board_ref must be supplied\n";
    my $player = shift
        || die "\$player must be supplied\n";

    _test_boardref( $board );
    _test_player( $player );

    my @possible_moves = @{ $player -> traverser() -> valid_cups( $player, $board ) };

    map {
            # if the move is valid, do it
            foreach my $move ( @possible_moves ) {
                # debug
                # print "trying move with rank ", $_ -> [RANK], ":", $_ -> [CUP] -> stones(), "\n";
                if ( $move == $_ -> [CUP] ) {
                    # debug
                    # print "match\n";
                    return $move;
                }
            }
        } sort { $b -> [RANK] <=> $a -> [RANK] }
            @{ $self -> ranking( $board, $player ) };
}

sub ranking {
    my $self = shift;
    my $board = shift
        || die "\$board_ref must be supplied\n";

    my $player = shift
        || die "\$player must be supplied\n";

    _test_boardref( $board );
    _test_player( $player );

    my $agent = $self -> {objects} -> {agent};
    my $agent_id = $self -> {objects} -> {agent_id};

    my %classes;
    my %instance = %{ $agent -> board_to_instance( $board, $player ) };

    my $all_inst_count = $agent -> get_all_instance_count( $agent_id );
    
    foreach my $class ( @{ $agent -> get_classes( $agent_id ) } ) {
        my $prob_class =
            $agent -> get_class_count( $agent_id, $class ) /
                $all_inst_count;
        foreach my $cup ( keys %instance ) {
            my $prob_inst_g_class =
                $agent -> get_instance_given_class_count( $agent_id, $class,
                    $cup => $instance{ $cup } )
                / $all_inst_count;
            $classes{ $class } += $prob_inst_g_class;
        }
        $classes{ $class } *= $prob_class;
    }

    # debug
    # use Data::Dumper;
    # print Dumper \%classes;

    my @cups;
    { # out of scope
        my $rank = 0;
        @cups = map { [ $rank++, $agent -> offset_cup( $board, $player, $_ ) ] }
            sort { $classes{$b} <=> $classes{$a} }
                keys %classes;
    }

    return \@cups;
}

1;
