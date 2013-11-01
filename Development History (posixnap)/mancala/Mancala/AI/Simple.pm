package Mancala::AI::Simple;

use strict;
use warnings;
use Exporter;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_ai/;
%EXPORT_TAGS = (
    'checks' => \@EXPORT_OK,
);

=head1 NAME

Mancala::AI::Simple - A simple Mancala AI class

=head1 SYNOPSIS

 # create a player with an AI
 use Mancala::Player::Machine;
 use Mancala::AI::Simple;

 my $player = Mancala::Player::Machine -> new(
    'AI' => 'Mancala::AI::Simple' );

=head1 ABSTRACT

This module is a super class for Mancala AI modules, it is not meant to be used alone and will not function.  Instead, all Mancala AI modules should inherit this module.

=head1 METHODS

The following methods are available:

=over 4

=item $ai = Mancala::AI::Simple -E<gt> new( %args );

This method returns a Mancala::AI::Simple object.  %args is a hash of initial values.  The required calues are detailed in the sub classes.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my %args = @_;

    return bless {
        'objects' => {
            %args,
        },
    }, $this;
}

=item $cup = $ai -E<gt> decide( $board_ref, $player );

This method takes a reference to a L<Mancala::Board|Mancala::Board> object and a L<Mancala::Player::Simple|Mancala::Player::Simple> object and returns the best move based on the AI functions.  This returs a L<Mancala::Cups::Simple|Mancala::Cups::Simple> object representing the best move.

Note: C<$board_ref> must be a reference to a constructed board object or this will fail.  In the case of failure, this method will return undef;

=cut

sub decide {
    die "The programmer forgot to overload decide(), shoot him\n";
}

=item $cup_ranking = $ai -E<gt> ranking( $board_ref, $player );

This method is similar to C<decide()> but returns all the possible cups.  It ranks these cups in order of the presidence.  Cups with a higher ranking are judged to be better than other cups with a lower ranking.

C<$cup_ranking> is in the form:

C<[
    [ rating, cup ],
    ...
]>

=cut

sub ranking {
    die "The programmer forgot to overload ranking(), shoot him\n";
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retvalue = _test_ai( $au );

This method performs a sanity check on the value C<$ai>.  It returns true if C<$ai> is a Mancala::AI::Simple of compatable object.  On a negative, this method C<die>s.

This method is exported with the export tag C<:checks>.

=cut

sub _test_ai {
    my $ai = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects Mancala::AI::Simple or compatable object object\n";

    die unless ref $ai
        and $ai -> can( 'decide' )
        and $ai -> can( 'ranking' );

    return $ai;
}

=back

=cut

1;
