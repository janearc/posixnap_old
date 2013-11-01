package Mancala::Board;

use strict;
use warnings;
use Data::Dumper;
use Exporter;
use Mancala::Board::Side qw/:checks/;
use Mancala::Player::Simple qw/:checks/;
use Mancala::Cups::Simple qw/:checks/;
use Clone;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter Clone/;
@EXPORT_OK = qw/_test_boardref/;
%EXPORT_TAGS = (
    'checks' => [qw/_test_boardref/]
);

=head1 NAME

Mancala::Board - Mancala board object

=head1 SYNOPSIS

 # create a board object and fetch data about it
 use Mancala::Board;

 my $board = Mancala::Board -> new();

 $board -> players( [$player1, $player2] );

 $board -> create();

 my @sides = @{ $board -> sides() };

=head1 ABSTRACT

This module creates a mancala board using L<Mancala::Board::Side|Mancala::Board::Side> and L<Mancala::Cups::Simple|Mancala::Cups::Simple> objects.  It creates a two dimensional board based on the number of players passed.

=head1 METHODS

The following methods are available:

=over 4

=item $board = Mancala::Board -E<gt> new( %args );

This method returns a Mancala::Board object.  %args os a hash of optional values.  The possible key/valye pair arguments are described below:

  KEY           DEFAULT
  --------      --------
  players       undef
  cups          undef
  stones        undef
  create        undef

C<players> is an arrayref of L<Mancala::Player::Simple|MAncala::Player::Simple> objects representing the players attending the game.  This effects how many sides are generated on the board.

C<cups> is the number of cups to be generated on each side of the game board.  This value is undef here as the default is set in L<Mancala::Cups::Simple|Mancala::Cups::Simple>.  See L<Mancala::Cups::Simple> before setting this value.

C<stones> is a scalar representing the default number of stones to place in every cup when the board is generated.  This value is undef here as the default is set in L<Mancala::Board::Side|Mancala::Board::Side>.

C<create>, when set, causes the board object returned to be completely created.  This removes the need for C<create()> to be called.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args )  = @_;

    my ( $players, $cups, $stones );

    if ( $args{ players }
        and _test_player_arrayref( $args{ players } ) ) {
        
        $players = delete $args{ players };
    }

    if ( $args{ cups }
        and _test_int( $args{ cups } ) ) {

        $cups = delete $args{ cups };
    }

    if ( $args{ stones }
        and _test_stones( $args{ stones } ) ) {

        $stones = $args{ stones };
    }

    my $self = bless {
        'objects' => {
            'players' => $players,
            'cups' => $cups,
            'stones' => $stones,
            'sides' => [ ],
        }
    }, $this;

    if ( $args{ create } )
        { $self -> create() }

    return $self;
}

=item $board -E<gt> players();

This method sets and returns the list of players in playing the game.  When given an array of L<Mancala::Player::Simple|Mancala::Player::Simple> objects, those objects are stored to be called apon later when C<create()> is called.  WARNING: do not set the players if a game is currently in progress on this board.  This may dammage the board, making play unpredictable.

This method also returns an arrayref of the players currently registered on this bame board.

=cut

sub players {
    my $self = shift;

    # if there are arguments
    if ( @_ ) {

        # fetch the players
        my $players = shift;

        # verify and set the players
        die "must take arrayref"
            unless ( ref $players eq "ARRAY" );

        my @plrs = @{ $players };

        foreach my $p ( @plrs ) {
            die "must take an arrayref of player objects"
                unless ( _test_player( $p ) );
        }

        $self -> {objects} -> {players} = $players;
    }

    # return the players
    return $self -> {objects} -> {players};
}

=item $board -E<gt> create();

This method generates a board based on previously set values.  If this module was created using C<'create' =E<gt> 1>, there is no need to run this, unless alterations were made in the board's parametersech my $p ( @plrs ) {


=cut

sub create {
    my $self = shift;

    die "board must have players before creation\n"
        unless ( $self -> {objects} -> {players} );

    my @players = @{ $self -> {objects} -> {players} };
    my $cups = $self -> {objects} -> {cups};
    my $stones = $self -> {objects} -> {stones};
    my @sides;
    my $side_count = scalar @players;

    for ( 0 .. $side_count-1 ) {
        $sides[$_] = Mancala::Board::Side -> new(
            'owner' => $players[$_],
            'cups' => $cups, 'stones' => $stones,
            'create' => 1 );
    };

    for ( 0 .. $side_count-1 ) {
        $sides[$_] -> connect_side( $sides[($_+1) % $side_count] );
    }

    $self -> {objects} -> {sides} = \@sides;

    return 1;
}

=item $sides = $board -E<gt> sides( $opt_val );

This method returns an arrayref of the sides contained on this game board.  If an index is passed, this method will return the side at the given index.  If a player object is passed, this method will return the side belonging to the player.

Note: this may return undef if the board has not been created.

=cut

sub sides {
    my $self = shift;

    if ( @_ ) {
        my $val = shift;

        # if a player object was passed, return player's side
        if ( eval { _test_player( $val ) } ) {
            my $side = $self -> sides(0);

            while ( $side -> owner() -> id() != $val -> id() )
                { $side = $side -> next() }

            return $side;
        # $val is probably an int
        } else {
            _test_int( $val );
            return ${ $self -> {objects} -> {sides} }[$val];
        }
    }

    return $self -> {objects} -> {sides};
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_boardref( $board_ref );

This method performs a sanity check on the value C<$board_ref>. It returns true if C<$board_ref> is a reference to a board object.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag;

=cut

sub _test_boardref {
    my $boardref = shift;

    die "must take ref"
        unless ( ref $boardref );

    die "must take a boardref"
        unless ref ${ $boardref };

    die "must take a boardref"
        unless ( ${ $boardref } -> can( 'players' )
            and ${ $boardref } -> can( 'sides' ) );

    return 1;
}

=back

=cut

1;
