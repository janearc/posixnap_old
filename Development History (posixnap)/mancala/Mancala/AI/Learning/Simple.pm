package Mancala::AI::Learning::Simple;

use strict;
use warnings;
use Mancala::AI::Simple;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::AI::Simple/;

sub new {
    my $that = shift;

    my $self = Mancala::AI::Simple::new(
        $that, @_ );

    die "Every learner needs an agent id number\n"
        unless $self -> {objects} -> {agent_id};

    die "Every learner needs an agent\n"
        unless $self -> {objects} -> {agent};

    return $self;
}

1;
