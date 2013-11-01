package Mancala::AI::Handful;

use constant RANK => 0;
use constant CUP => 1;

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

Mancala::AI::Handful - A Mancala AI

=head1 SYNOPSIS

 # create a player with an ai
 use Mancala::Player::Machine;
 use Mancala::AI::Handful;

 my $player = Mancala::Player::Machine -> new(
    'AI' => 'Mancala::AI::Handful' );

=head1 ABSTRACT

This is a Mancala AI.  A player using this AI will always pick the cup with the most stones in it.  In the case of equal numbered stones, it choses randomly between them.

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

    my $board = shift
        || die "\$board_ref must be supplied\n";

    my $player = shift
        || die "\$player must be supplied\n";

    _test_boardref( $board );
    _test_player( $player );

    my @valid_cups
        = @{ $player -> traverser() -> valid_cups( $player, $board ) };

    my @array = map { [ $_ -> stones(), $_ ] } @valid_cups;

    return \@array;
}

1;
