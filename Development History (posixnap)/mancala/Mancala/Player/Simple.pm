package Mancala::Player::Simple;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use Mancala::Display::Simple qw/:checks/;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_name _test_player _test_player_arrayref/;
%EXPORT_TAGS = (
    'checks' => [qw/_test_name _test_player _test_player_arrayref/]
);

=head1 NAME

Mancala::Player::Simple - A simple mancala player

=head1 SYNOPSIS

 # create a player

 use Mancala::Player::Simple;

 my $player = Mancala::Player::Simple -> new();

 $player -> name( 'Bob' );

=head1 ABSTRACT

This module is designed to store player information.

=head1 METHODS

The following methods are available:

=over 4

=item $player = Mancala::Player::Simple -E<gt> new( %args );

This method returns a Mancala::Player::Simple pbject.  %args is a hash of initial values.  The possible key/value pair arguments are described below:

  KEY           DEFAULT
  --------      --------
  name          Player
  display       Mancala::Display::Simple -> new()
  traverser     Mancala::Board::Traverser::Classic -> new()

C<name> is the name of the player.  It is strongly suggested that players have unique names.

C<display> is the display object to be used when interacting with this player.  This is required for human players, elsewize play is unpredictable.

C<traverser> is the traverser to be used with this player.  This dictates the rules by which this player operates and can infact allow different players to play with different rules or difficulties.  Time value must be set before gameplay can begin.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args ) = @_;

    my ( $name, $id, $display, $traverser );

    if ( $args{ name }
        and _test_name( $args{ name } ) ) {

        $name = delete $args{ name };
    } else {
        $name = 'Player ';
        $name .= int rand 1000;
    }

    if ( defined $args{ display }
        and _test_display( $args{ display } ) ) {

        $display = delete $args{ display };
    } else {
        $display = Mancala::Display::Simple -> new();
    }

    if ( $args{ traverser }
        and _test_traverser( $args{ traverser } ) ) {

        $traverser = delete $args{ traverser };
    } else {
        require Mancala::Board::Traverser::Classic;
        $traverser = Mancala::Board::Traverser::Classic -> new();
    }

    $id = int rand 10000;

    return bless {
        'objects' => {
            'name' => $name,
            'id' => $id,
            'display' => $display,
            'traverser' => $traverser,
        }
    }, $this;
}

=item $name = $player -E<gt> name();

This method sets and returns the player name.  When passed a scalar, the name is set to this scalar.

This method returns a scalar name and will never be null.

=cut

sub name {
    my $self = shift;

    # if there are arguments
    if ( @_ ) {

        # fetch the name value
        my $name = shift;

        # verify and set the name value
        $self -> {objects} -> {name} = $name
            if ( _test_name( $name ) );
    }

    # return the name value
    return $self -> {objects} -> {name};
}

=item $id = $player -E<gt> id();

This method returns the unique ID associated with every player.  This value is an integer generated when the object is constructed and is immutable.

=cut

sub id {
    my $self = shift;

    return $self -> {objects} -> {id};
}

=item $boardref = $player -E<gt> request_choice( $board );

This method requests an action from the player.  This is called when it is this player's turn to act on the given board ref.  This returns a reference to the board that has been acted on.

=cut

sub request_choice {
    die "this method should have been overloaded, something is wrong here\n";
}

=item $traverser = $player -E<gt> traverser();

This method returns the L<traverser|Mancala::Board::Traverser::Simple> object used by this player.  This value will always be set.

=cut

sub traverser {
    my $self = shift;
    return $self -> {objects} -> {traverser};
}

=item $display = $player -E<gt> display();

This method returns the L<display|Mancala::Display::Simple> object used by this player.  This value will always be set.


=cut

sub display {
    my $self = shift;
    return $self -> {objects} -> {display};
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_name( $name );

This method performs a sanity check on the value C<$name>.  It returns true if C<$name> is a scalar.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag;

=cut

sub _test_name {
    my $name = shift;
    return 1 unless ref $name;
    die "\$name must be a scalar\n";
}

=item $retval = _test_player( $player );

This method performs a sanity check on the value C<$player>.  It returns true if C<$player> is a L<Mancala::Player::Simple|Mancala::Player::Simple> or compatable object.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag;

=cut

sub _test_player {
    my $player = shift;
    return 1 if ref $player
        and $player -> can( 'name' )
        and $player -> can( 'id' );
    die "\$player must be a player object\n";
}

=item $retval = _test_player_arrayref( $player_arrayref );

This method performs a sanity check on the value C<$player_arrayref>.  It returns true if C<$player_arrayref> is an arrayref containing L<Mancala::Player::Simple|Mancala::Player::Simple> or compatable object.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag;

=cut

sub _test_player_arrayref {
    my $players = shift;

    die "must take arrayref"
        unless ( ref $players eq "ARRAY" );

    my @plrs = @{ $players };

    foreach my $p ( @plrs ) {
        die "must take an arrayref of player objects"
            unless ( _test_player( $p ) );
    }

    return 1;
}

=back

=cut

1;
