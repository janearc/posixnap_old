package Mancala::AI::Random;

use constant RANK => 0;
use constant CUP => 1;

use strict;
use warnings;
use Data::Dumper;
use Mancala::Board qw/:checks/;
use Mancala::Player::Simple qw/:checks/;
use Mancala::AI::Simple;

use vars qw/@ISA/;

@ISA = qw/Mancala::AI::Simple/;

=head1 NAME

Mancala::AI::Random - A random move AI

=head1 SYNOPSIS

 # create an ai object
 use Mancala::AI::Random

 my $random = Mancala::AI::Random -> new();

=head1 ABSTRACT

This is an AI for a Mancala game.  It essentially finds all valid moves and choses randomly amongst them.

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
        || die "\$player myst be supplied\n";

    _test_boardref( $board );
    _test_player( $player );

    my @valid_cups
        = @{ $player -> traverser() -> valid_cups( $player, $board ) };

    # do the schwartzian thing
    my @array = map { [ int( $_ -> [RANK] * @valid_cups ), $_ -> [CUP] ] }
        sort { $a -> [RANK] <=> $b -> [RANK] }
        map { [rand(), $_] } ( @valid_cups );

    return \@array;
}

1;
