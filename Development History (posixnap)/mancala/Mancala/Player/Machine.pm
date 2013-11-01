package Mancala::Player::Machine;

use strict;
use warnings;
use Data::Dumper;
use Mancala::Player::Simple;
use Mancala::Board qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::Player::Simple/;

=head1 NAME

Mancala::Player::Machine - A machine player for Mancala

=head1 SYNOPSIS

 # create a machine player
 use Mancala::Player::Human;

 my $player = Mancala::Player::Human -> new(
    'AI' => 'Mancala::AI::Simple' );

=head1 ABSTRACT

This is an object represeting a machine player for Mancala.  It is fully compatable with a L<Mancala::Player::Human|Mancala::Player::Human> object.  It makes choices based on an AI module specified during construction.

See L<Mancala::AI::Simple>.

=head1 METHODS

The following methods are different than the ones found in L<Mancala::Player::Simple|Mancala::Player::Simple>.

=over 4

=item $player = Mancala::Player::Machine -E<gt> new( %args );

This method acts the same as the one found in L<Mancala::Player::Simple|Mancala::Player::Simple> but it requires one additional hash argument.  This method must be given an AI to play.

  C<'AI' => 'Mancala::AI::Simple'>

Replace Simple with the name of the intelligence to be used;

=cut

sub new {
    my $that = shift;

    my $self = Mancala::Player::Simple::new( $that, @_ );

    my %args = @_;

    # hide this, its bad
    { no strict qw/refs/;
        if ( $args{ AI } and eval "require $args{ AI }" ) {

            $self -> {objects} -> {ai}
                = eval "$args{ AI } -> new( %args )";
            die "$@" if $@;
        } else {
            die "new() requires an AI parameter\n";
        }
    }

    # append to name
    $self -> {objects} -> {name}
        .= " (".$args{ AI }.")";

    return $self;
}

=item $cup = $player -E<gt> request_choice( $board_ref );

This method returns a cup chosen by the AI method this machine player uses.

=cut

sub request_choice {
    my $self = shift;

    my $board = shift
        || die "\$board must be supplied\n";

    _test_boardref( $board );

    my $ai = $self -> {objects} -> {ai};

    my $cup = $ai -> decide( $board, $self );

    die "something went wrong with the ai\n"
        unless ( $cup );

    return $cup;
}

=back

=cut

1;
