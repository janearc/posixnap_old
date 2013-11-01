package Mancala::DB::Simple;

use strict;
use warnings;
use Mancala::Board qw/:checks/;
use Mancala::Cups::Simple qw/:checks/;
use Mancala::Player::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw//;

sub new {
    die "Mancala::DB::Simple::new() must be overloaded\n";
}

sub cup_offset {
    my $self = shift;
    my $boardref = shift
        || die "\$board_ref must be supplied\n";
    my $player = shift
        || die "\$player must be supplied\n";
    my $choice_cup = shift
        || die "\$cup must be supplied\n";

    _test_boardref( $boardref );
    _test_player( $player );
    _test_cup( $choice_cup );

    my $offset = 0;

    my $first_cup = ${ $boardref } -> sides( $player ) -> first_cup();

    { # take this out of scope again
        my $cup = $first_cup;

        until ( $cup == $choice_cup ) {
            $offset++
                unless $cup -> is_goal();
            $cup = $cup -> next();
        }
    }

    return $offset;
}

sub offset_cup {
    my $self = shift;
    my $boardref = shift
        || die "\$board_ref must be supplied\n";
    my $player = shift
        || die "\$player must be supplied\n";
    my $offset = shift;

    die "\$offset must be supplied\n"
        unless defined $offset;

    my $cup = ${ $boardref } -> sides( $player ) -> first_cup();

    until ( $offset == 0 ) {
        $cup = $cup -> next();
        $offset--
            unless $cup -> is_goal();
    }

    return $cup;
}

sub board_to_instance {
    my $self = shift;
    my $boardref = shift
        || die "boardref expected\n";
    my $player = shift
        || die "player expected\n";

    _test_boardref( $boardref );
    _test_player( $player );

    my %instance;

    my $first_cup = ${ $boardref } -> sides( $player ) -> first_cup();

    { # take this out of scope
        $instance{0} = $first_cup -> stones();
        my $cup = $first_cup -> next();
        my $i = 0;

        until ( $cup == $first_cup ) {
            $instance{++$i} = $cup -> stones()
                unless $cup -> is_goal();
            $cup = $cup -> next();
        }
    }

    return \%instance;
}

1;
