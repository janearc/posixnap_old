package Mancala::Cups::Simple;

use constant DEFAULT_STONES => 0;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use Mancala::Player::Simple qw/:checks/;
use Mancala::Board::Side qw/:checks/;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_cup _test_stones _test_int/;
%EXPORT_TAGS = (
    'checks' => [qw/_test_cup _test_stones _test_int/]
);

=head1 NAME

Mancala::Cups::Simple - A simple Mancala cup object

=head1 SYNOPSIS

 # create an array of cup objects and connect
 # them to eachother.

 # note: next() cup is in decending order
 # ie. $cup[1] -> next == $cup[0]

 use Mancala::Cups::Simple;

 my @cup;
 for ( 0 .. 1 ) {
     $cup[$_] = Mancala::Cups::Simple -> new( { stones => $_ } );
 }

 for ( 0 .. 1 ) {
     $cup[$_] -> next( $_ ? $cup[$_-1] : $cup[1] );
 }

 print $cup[0] -> stones(), "\n";
 print $cup[0] -> next() -> stones(), "\n";

 $cup[0] -> is_goal()
     ? print "cup 0 is a goal cup\n"
     : print "cup 0 is not a goal cup\n";

=head1 ABSTRACT

This module is a simple representation of a game cup for mancala.  It knows how stores how many stones it has and the position of the next cup as well as several other cup related information.

This module is not meant to be used directly but instead exists as a simple module to be inherited by others.  See L<Mancala::Cups::Board> and L<Mancala::Cups::Goal>.

=head1 METHODS

The following methods are available:

=over 4

=item $cup = Mancala::Cups::Simple -E<gt> new( %args );

This method returns a Mancala::Cups::Simple object.  %args is a hash of initial values.  The possible key/value pair arguments are described below:

  KEY           DEFAULT
  --------      --------
  next          undef
  stones        0
  owner         undef

C<next> is the location of the next cup in relation to the current cup.  It is not required for wach cup to have a next value but it is recommended for proper function.

C<stones> is the number of stones stored in the current cup.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args ) = @_;

    my ( $next, $stones, $owner, $side );

    if ( $args{ stones }
        and _test_stones( $args{ stones } ) ) {

        $stones = delete $args{ stones };
    } else {
        $stones = DEFAULT_STONES();
    }

    if ( $args{ owner }
        and _test_player( $args{ owner } ) ) {

        $owner = delete $args{ owner };
    }

    if ( $args{ next } 
        and _test_cup( $args{ next } ) ) {

        $next = delete $args{ next };
    }

    if ( $args{ side }
        and _test_side( $args{ side } ) ) {
        $side = $args{ side };
    }

    return bless {
        'objects' => {
            'next' => $next,
            'stones' => $stones,
            'owner' => $owner,
            'side' => $side,
        },
    }, $this;
}

=item $next = $cup -E<gt> next();

This method sets and returns the next cup value.  The next cup value holds the cup which appears next in relation to the current cup.  When passed a cup object, the next cup value is set to the given cup object.

This method returns a cup object or null if the next cup value is unset.

=cut

sub next {
    my $self = shift;

    # if there are arguments
    if ( @_ ) {

        # fetch the value next
        my $next = shift;

        # verify and set the value next
        $self -> {objects} -> {next} = $next
            if _test_cup( $next );
    }

    # return the value next
    return $self -> {objects} -> {next};
}

=item $stones = $cup -E<gt> stones();

This method sets and returns the number of stones currently held in the current cup.  This value will always be an integer.  When given an integer argument, it will set the number of stones to the given integer.

This method never returns a null value.  By default, the number of stones is 0.

=cut

sub stones {
    my $self = shift;

    # if there are arguments
    if ( @_ ) {
        
        # fetch the stone count
        my $stones = shift;

        # verify and set the stones value
        $self -> {objects} -> {stones} = $stones
            if _test_stones( $stones );
    }

    # return the stones value
    return $self -> {objects} -> {stones};
}

=item $owner = $cup -E<gt> owner();

This method sets and returns the owner of the cup.  When given a player object, it will set the owner of the cup.

This method also returns the owner of the cup.

=cut

sub owner {
    my $self = shift;

    # if there are arguments
    if ( @_ ) {

        # fetch the cup owner
        my $owner = shift;

        # verify and set the owner
        $self -> {objects} -> {owner} = $owner
            if _test_player( $owner );
    }

    # return the cup owner
    return $self -> {objects} -> {owner};
}

=item $cup -E<gt> inc();

This method increments the stone count by one.  This method always returns true.

=cut

sub inc {
    my $self = shift;

    # increment
    $self -> {objects} -> {stones}++;

    return 1;
}

=item $stones = $cup -E<gt> empty();

This method removes all stones from the cup and returns the number of stones removed.  This will never return undef.

=cut

sub empty {
    my $self = shift;

    # fetch the number of stones, 0 if undefined;
    my $stones = $self -> {objects} -> {stones} || 0;

    # empty the cup
    $self -> {objects} -> {stones} = 0;

    return $stones;
}

=item $goal = $cup -E<gt> is_goal();

This returns true of the given cup is a goal cup.  This method is designed to be overwritten by L<Mancala::Cups::Board|Mancala::Cups::Board> and L<Mancala::Cups::Goal|Mancala::Cups::Board>.

=cut

sub is_goal {
    return undef;
}

=item $stones = $cup -E<gt> default_stones();

This returns the default number of stones for this type of cup.  This method is designed to be overwritten by L<Mancala::Cups::Board|Mancala::Cups::Board> and L<Mancala::Cups::Goal|Mancala::Cups::Board>.

=cut

sub default_stones {
    return undef;
}

=back


=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retvalue = _test_cup( $cup );

This method performs a sanity check on the value C<$cup>.  It returns true if C<$cup> is a L<Mancala::Cups::Simple|Mancala::Cups::Simple> or compatable object.  On a negative, this method C<die>s.

This is also exported when given the C<:checks> tag;

=cut

sub _test_cup {
    my $next = shift;
    return 1 if ref $next
        and $next -> can( 'next')
        and $next -> can( 'stones' );
    die "\$cup must be a cup object\n";
}

=item $retvalue = _test_int( $int );

This method performs a sanity check on the value C<$int>.  It returns true if C<$int> is a scalar integer.  On a negative match, this method returns undef.

This is also exported when given the C<:checks> tag;

=cut

sub _test_int {
    my $int = shift;
    return 1 if $int eq int( $int );
    return undef;
}

=item $retval = _test_stones( $stones );

This method acts like C<_test_int> but dies on failure.

This is also exported when given the C<:checks> tag;

=cut

sub _test_stones {
    my $stones = shift;
    if ( _test_int( $stones ) )
        { return 1 }
    die "\$stones must be an integer\n";
}

=back

=cut

1;
