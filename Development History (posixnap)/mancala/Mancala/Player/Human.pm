package Mancala::Player::Human;

use strict;
use warnings;
use Data::Dumper;
use Mancala::Player::Simple;
use Mancala::Board qw/:checks/;
use Mancala::Display::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::Player::Simple/;

=head1 NAME

Mancala::Player::Human;

=head1 SYNOPSIS

 # create a player object
 use Mancala::Player::Human;

 my $player = Mancala::Player::Human -> new();

=head1 ABSTRACT

This module is a subclass of L<Mancala::Player::Simple|Mancala::Player::Simple>.  It provides a human interface to the mancala game, giving user prompts and displays.  See L<Mancala::Player::Simple>.

=cut

sub new {
    my $that = shift;

    my $self = Mancala::Player::Simple::new( $that, @_ );

    # append name
    $self -> {objects} -> {name} .= " (human)";
    
    return $self;
}

sub request_choice {
    my $self = shift;
    my $board = shift;

    _test_boardref( $board );

    my @sides = @ {${ $board } -> sides() };
    my $display = $self -> {objects} -> {display};
    my $traverser = $self -> {objects} -> {traverser};

    $display -> display_board( $board );

    my $choice;
    until ( $choice ) {
        my $value;
        until ( $value = $display -> display_prompt() ) { }

        my $cup_offset = ( $value -> [0] - 1 )
            * ( $sides[0] -> cups() + 1 )
            + ( $value -> [1] - 1 );

        my $cup = $sides[0] -> first_cup();

        while ( $cup_offset-- )
            { $cup = $cup -> next() }

        if ( $traverser -> validate( $cup, $self, $board ) )
            { $choice = $cup }
    }

    return $choice;
}

1;
