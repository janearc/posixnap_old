package Mancala::AI::Learning::Helpers::Simple;

use strict;
use warnings;
use Mancala::AI::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
#@ISA = qw//;
@ISA = qw/Mancala::AI::Simple/;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $piggyback = $args{piggyback}
        or die "All Learning Helper modules require a piggyback module to assist in learning\n";
    _test_ai( $piggyback );

    my $agent = $args{agent}
        or die "All Learning Helper modules require a database agent\n";

    my $agent_id = $args{agent_id}
        or die "All Learning Helper modules require an agent_id\n";

    return bless {
        objects => {
            piggyback => $piggyback,
            agent => $agent,
            agent_id => $agent_id,
        },
    }, $this;
}

sub ranking {
    my $self = shift;
    return $self -> {objects} -> {piggyback} -> ranking( @_ );
}

1;
