package Mancala::Board::Side;

use constant DEFAULT_CUPS => 6;
use constant DEFAULT_STONES => 3;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use Mancala::Cups::Simple qw/:checks/;
use Mancala::Cups::Board;
use Mancala::Cups::Goal;
use Mancala::Player::Simple qw/:checks/;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_side/;
%EXPORT_TAGS = (
    'checks' => [qw/_test_side/]
);


=head1 NAME

Mancala::Board::Side - A module representing one player side of the moncala board.

=head1 SYNOPSYS

 # create a side and populate it with cups

 use Mancala::Board::Side;

 my $side = Mancala::Board::Side -> new();

 $side -> owner( $player );

=head1 ABSTRACT

This module represents one side of a mancala game board.  A side is a series of linked mancala cups ending in a goal cup, all owned by one player.  See -L<Mancala::Cups::Simple> and L<Mancala::Player::Simple>.

=head1 METHODS

The following methods are available:

=over 4

=item $side = Mancala::Board::Side -E<gt> new( %args );

This method returns a Mancala::Board::Side object.  %args is an optional hash of initial values.  The possible key/value pair arguments are described below:

  KEY           DEFAULT
  ________      ________
  owner         undef
  cups          6
  stones        3
  create        undef

C<owner> is the player which owns this side of the board.  This is a L<Mancala::Player::Simple|Mancala::Player::Simple> object.

C<cups> is the number of cups in this section of the game board.  This should be a multiple of the number of players, otherwise infinite looping may occur.

C<stones> is the number of stones initially placed in each cup.

C<create> skips a step by returning a L<Mancala::Board::Side|Mancala::Board::Side> object in which the cups have already been created.  This essentially runs C<create()> before returning.  When using this, all that is left to do is link the board.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args ) = @_;

    my ( $owner, $cups, $stones );

    if ( $args{ owner }
        and _test_player( $args{ owner } ) ) {

        $owner = delete $args{ owner };
    }

    if ( $args{ cups }
        and _test_int( $args{ cups } ) ) {

        $cups = delete $args{ cups };
    } else {
        $cups = DEFAULT_CUPS();
    }

    if ( $args{ stones }
        and _test_stones( $args{ stones } ) ) {
        
        $stones = delete $args{ stones };
    } else {
        $stones = DEFAULT_STONES();
    }

    my $self = bless {
        'objects' => {
            'owner' => $owner,
            'cups' => $cups,
            'first_cup' => undef,
            'goal_cup' => undef,
            'stones' => $stones,
            'next' => undef,
        }
    }, $this;

    if ( $args{ create } )
        { $self -> create() }

    return $self;
}

=item $owner = $side -E<gt> owner();

This method sets and returns the owner of this board side.  The owner value dictates who is allowed to chose cups from this side of the board.  When passed a L<Mancala::Player::Simple|Mancala::Player::Simple> object, this value is set to that object.
This method also returns the set value for the owner.

=cut

sub owner {
    my $self = shift;

    # if there are arguments
    if ( @_ ) {

        # fetch the owner
        my $owner = shift;

        # verify the owner is a player object
        $self -> {objects} -> {owner} = $owner
            if _test_player( $owner );
    }

    # return the owner value
    return $self -> {objects} -> {owner};
}

=item $retval = $side -E<gt> create();

This method attempts to build the board side using the stored values.  Building the side means creating the cups and populating them with stones.

=cut

sub create {
    my $self = shift;

    my $cups = $self -> {objects} -> {cups};
    my $owner = $self -> {objects} -> {owner};
    my $stones = $self -> {objects} -> {stones};

    my %args = ( 'owner' => $owner, 'stones' => $stones );

    my $cup = $self -> {objects} -> {first_cup} = Mancala::Cups::Board -> new( %args );

    $cup = $cup -> next( Mancala::Cups::Board -> new( %args ) )
        for ( 2 .. $cups );

    my $goal = $self -> {objects} -> {goal_cup} = Mancala::Cups::Goal -> new( 'owner' => $owner );
    $cup -> next( $goal );

    return 1;
}

=item $retval = $side -E<gt> connect_side( $side );

This method attempts to connect the last cup on this side with the first cup on C<$side>.  This essentially connects the end of one linked list with another, directing the direction of gameplay.  A side can be connected to no more than one other side.  Using this function again will break the the previous connection in favor of the new one.

=cut

sub connect_side {
    my $self = shift;

    my $side = shift
        || die "must supply a \$side\n";

    my $last_cup = $self -> {objects} -> {goal_cup};
    my $next_first_cup = $side -> {objects} -> {first_cup};

    unless ( $last_cup and $next_first_cup ) {
        die "both board sides must have a atleast one board cup. perhaps you forgot to run create()\n" };

    $last_cup -> next( $next_first_cup );

    $self -> {objects} -> {next} = $side;

    return 1;
}

=item $next_side = $side -E<gt> next();

This method returns the C<Mancala::Board::Side> or compatable object of which C<$side> connects to.  This is set using the C<Connect_side()> function.  If this is unset, returns undef.

=cut

sub next {
    my $self = shift;

    return $self -> {objects} -> {next};
}

=item $cups = $side -E<gt> cups();

This method returns the number of cups contained on this board side.  If cups were not generated, this returns undef.

=cut

sub cups {
    my $self = shift;

    return $self -> {objects} -> {cups};
}

=item $cup = $side -E<gt> first_cup();

This method returns the C<Mancala::Cups::Cimple> or compatable object stored as the first cup on this board side.  If this is unset, returns undef.

=cut

sub first_cup {
    my $self = shift;

    return $self -> {objects} -> {first_cup};
}

=item $cup = $side -E<gt> goal_cup();

This method returns the C<Mancala::Cups::Cimple> or compatable object stored as the goal cup on this side.  If this is unset, returns undef.

=cut

sub goal_cup {
    my $self = shift;

    return $self -> {objects} -> {goal_cup};
}

=item $retval = $side -E<gt> is_empty();

This method returns true if all L<Mancala::Cups::Simple|Mancala::Cups::Simple> objects contained on this side contain no stones.  This does not include the L<goal cup|MAncala::Cups::Goal>.  This returns undef if the side has not been generated.

=cut

sub is_empty {
    my $self = shift;

    my $cup = $self -> first_cup();
    my $goal = $self -> goal_cup();

    return undef unless _test_cup( $cup );

    while ( $cup != $goal ) {
        return undef 
            if $cup -> stones();
        $cup = $cup -> next();
    }

    return 1;
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_side( $side );

This method performs a sanity check on the value C<$side>.  It returns true if C<$side> is a L<Mancala::Board::Side|Mancala::Board::Side> or compatable object.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag;

=cut

sub _test_side {
    my $side = shift;
    return 1 if ref $side
        and $side -> can( 'owner' );
    die "\$side must be a board side object\n";
}

=back

=cut

1;
