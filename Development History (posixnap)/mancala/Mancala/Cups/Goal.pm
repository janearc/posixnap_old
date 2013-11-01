package Mancala::Cups::Goal;

use constant DEFAULT_STONES => 0;

use strict;
use warnings;

use Mancala::Cups::Simple;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::Cups::Simple/;

=head1 NAME

Mancala::Cups::Goal - A mancala goal cup object

=head1 SYNOPSIS

See L<Mancala::Cups::Simple>

=head1 ABSTRACT

This module is a variant of L<Mancala::Cups::Simple|Mancala::Cups::Simple>, relating to the altered use of goal cups.

=cut

sub is_goal {
    return 1;
}

sub default_stones {
    return DEFAULT_STONES;
}

1;
