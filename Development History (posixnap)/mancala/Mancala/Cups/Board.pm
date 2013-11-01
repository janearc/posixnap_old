package Mancala::Cups::Board;

use constant DEFAULT_STONES => 3;

use strict;
use warnings;

use Mancala::Cups::Simple;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::Cups::Simple/;

=head1 NAME

Mancala::Cups::Board - A mancala board cup object

=head1 SYNOPSIS

See L<Mancala::Cups::Simple>

=head1 ABSTRACT

This module is a variant of L<Mancala::Cups::Simple|Mancala::Cups::Simple>, relating to the altered use of simple board cups.

=cut

sub is_goal {
    return 0;
}

sub default_stones {
    return DEFAULT_STONES;
}

1;
