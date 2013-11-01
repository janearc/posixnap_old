package Mancala::Display::ASCII;

use constant PLAYER => 0;
use constant SCORE => 1;

use strict;
use warnings;
use Data::Dumper;
use Mancala::Board qw/:checks/;
use Mancala::Board::Side qw/:checks/;
use Mancala::Display::Simple qw/:checks/;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::Display::Simple/;

=head1 NAME

Mancala::Display::ASCII - A module to display a mancala board using ASCII text

=head1 SYNOPSIS

 # create a display object and use it
 use Mancala::Display::ASCII;

 my $display = Mancala::Display::ASCII -> new();

 # display a side
 $display -> display_horizontal_side( $side );

=head1 ABSTRACT

This module is used to display elements of a Mancala::Board object in text format.

=head1 METHODS

The following methods are available:

=over 4

=item $display = Mancala::Display::ASCII -E<gt> new( %args );

This method returns a MAncala::Display::ASCII object.  %args is a hash of initial values.  The possible key/value pair arguments are described below:

Currently new() accepts no arguments.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args ) = @_;

    my %letters;
    {
        my $i = 0;
        for ( 'A' .. 'Z' ) { $letters{ $i++ } = $_ }
    }

    return bless {
        'objects' => {
            'trans_table' => \%letters,
        }
    }, $this;
}

=item $display -E<gt> display_board( $board_ref );

This method attempts to display a mancala board.  It requires a built L<Mancala::Board|Mancala::Board> object reference.

=cut

sub display_board {
    my $self = shift;
    my $board = shift
        || die "requires \$board\n";

    _test_boardref( $board );

    my $sides = ${ $board } -> sides();

    print "\n";
    $self -> display_score( $board );
    print "\n";

    if ( @{ $sides } == 2 ) { 
        $self -> display_horizontal_choices( $sides -> [0], 1 );
        $self -> display_horizontal_side( $sides -> [0] );
        print _display_horiz_div( scalar @{ _retrieve_stone_count( $sides -> [0] ) } ), "\n";
        $self -> display_reverse_horizontal_choices( $sides -> [1], 2 );
        $self -> display_reverse_horizontal_side( $sides -> [1] );
    } else {
        my $i = 1;
        foreach my $side ( @{ $sides } ) {
            $self -> display_horizontal_choices( $side, $i++ );
            $self -> display_horizontal_side( $side );
        }
    }

    print "\n";

    return 1;
}

=item $display -E<gt> display_score( $board_ref );

This method takes a L<Mancala::Board|Mancala::Board> reference and prints a score for each player in the game.  Board must have been created.  See L<Mancala::Board>.

=cut

sub display_score {
    my $self = shift;

    my $board = shift ||
        die "must supply \$board_ref\n";

    _test_boardref( $board );

    my $sides = ${ $board } -> sides();

    print "Score:\n";
    foreach my $side ( @{ $sides } ) {
        print "\t", $side -> owner() -> name(), " : ",
            $side -> goal_cup -> stones(), "\n";
    }

    return 1;
}

=item $display -E<gt> display_final_score( $board_ref );

This method takes a L<Mancala::Board|Mancala::Board> reference and prints a score for each player in the game.  Additionally, this prints the name of the winner.  Board must have been created.  See L<Mancala::Board>.

=cut

sub display_final_score {
    my $self = shift;

    my $board = shift ||
        die "must supply \$board_ref\n";

    _test_boardref( $board );

    my $sides = ${ $board } -> sides();

    $self -> display_score( $board );

    print "Winner:\n";
    my @player = ($sides -> [0] -> owner() -> name(), $sides -> [0] -> goal_cup() -> stones() );

    shift @{ $sides };

    foreach my $side ( @{ $sides } ) {
        my $stones = $side -> goal_cup() -> stones();
        if ( $stones > $player[SCORE] ) {
            @player = ( $side -> owner() -> name(), $stones );
        } elsif ( $stones == $player[SCORE] ) {
            push @player, $side -> owner() -> name(), $stones;
        }
    }

    if ( @player == 2 ) {
        print "Player '$player[PLAYER]' won with $player[SCORE] stones\n";
    } else {
        print "Tie between ";
        while ( @player > 2 ) {
            print "$player[PLAYER], ";
            shift @player; shift @player;
        }
        print "and $player[PLAYER] with $player[SCORE] stones\n";
    }

    return 1;
}


=item $display -E<gt> display_horizontal_choices( $side, $row );

This method is designed to accompany C<display_horizontal_side()>.  It prints a series of letters which will label the cups and allow the user to differentiate between them.  These letters are all capitalized and are spaced to align with the display of of the cups.  It must be passed a L<Mancala::Board::Side|Mancala::Board::Side> object.  Optionally a $row integer may be passed to augment the display.  This should be no more than 1 character in length.

This method will die if asked to print more than 26 labels for a row of cups as there are only 26 letters to choose from.

=cut

sub display_horizontal_choices {
    my $self = shift;

    my $side = shift
        || die "must supply \$side\n";

    my $row = shift;

    _test_side( $side );

    my $trans_table = $self -> {objects} -> {trans_table};

    my $cups = scalar @{ _retrieve_stone_count( $side ) } - 1;

    die "cannot display this number of cups"
        unless ( $cups <= 26 and $cups > 0 );

    my $f = "        ";
    while ( $cups-- ) {
        $f .= "   ". $trans_table -> {$cups}. "    ";
    }

    # add row numbers is given
    if ( $row )
        { $f =~ s/(\w)./$row$1/g }

    print "$f\n";
    return 1;
}

=item $display -E<gt> display_reverse_horizontal_choices( $side, $row );

This method is similar to C<display_horizontal_choices()> except it prints choices in reverse order.  It is designed to accompany C<display_reverse_horizontal_side()>.

=cut

sub display_reverse_horizontal_choices {
    my $self = shift;

    my $side = shift
        || die "must supply \$side\n";

    my $row = shift;

    _test_side( $side );

    my $trans_table = $self -> {objects} -> {trans_table};

    my $cups = scalar @{ _retrieve_stone_count( $side ) } - 1;

    die "cannot display this number of cups"
        unless ( $cups <= 26 and $cups > 0 );

    my $f = '';
    while ( $cups-- ) {
        $f = "   ". $trans_table -> {$cups}. "    ". $f;
    }

    # add row numbers is given
    if ( $row )
        { $f =~ s/(\w)./$row$1/g }

    print "$f\n";
    return 1;
}

=item $display -E<gt> display_horizontal_side( $side );

This method displays one side of the mancala board.  $side is required.

Output will be similar to this:

    ___     ___     ___     ___   
   /   \   /   \   /   \   /   \  
  |  3  | |  3  | |  3  | |  0  | 
   \___/   \___/   \___/   \___/  

=cut

sub display_horizontal_side {
    my $self = shift;

    my $side = shift
        || die "must supply \$side\n";

    _test_side( $side );

    # retrieve the stones
    my @stones = reverse @{ _retrieve_stone_count( $side ) };
    
    # display
    print _display_horiz_side( @stones ), "\n";

    return 1;
}

=item d$display -E<gt> isplay_reverse_horizontal_side( $side );

This method acts like C<display_horizontal_side()> with the alteration of displaying the cups in reverse order.

Given the same data as C<display_horizontal_side()>, output will appear like this:

    ___     ___     ___     ___   
   /   \   /   \   /   \   /   \  
  |  0  | |  3  | |  3  | |  3  | 
   \___/   \___/   \___/   \___/  

=cut

sub display_reverse_horizontal_side {
    my $self = shift;

    my $side = shift
        || die "must supply \$side\n";

    _test_side( $side );

    # retrieve the reverse stone count
    my @stones = @{ _retrieve_stone_count( $side ) };

    # display
    print _display_horiz_side( @stones ), "\n";

    return 1;
}

=item $display -E<gt> display_vertical_side( $side );

This method, like the others in this module display a side of the board.  This displays a side but in a vertical manner.

Output will be similar to this:

=cut

sub display_vertical_side {
    my $self = shift;

    my $side = shift
        || die "must supply \$side\n";

    _test_side( $side );

    # retrieve the stone count
    my @stones = @{ _retrieve_stone_count( $side ) };

    # display
    print _display_vert_side( @stones );

    return 1;
}

=item $display -E<gt> display_reverse_vertical_side( $side );

As expected, this method displays output similar to C<display_vertical_side> but in reverse order.

Given the same side, output will be thus:

=cut

sub display_reverse_vertical_side {
    my $self = shift;

    my $side = shift
        || die "must supply \$side\n";

    _test_side( $side );

    # retrieve the reverse stone count
    my @stones = reverse @{ _retrieve_stone_count( $side ) };

    # display
    print _display_vert_side( @stones );

    return 1;
}

=item $choice = $display -E<gt> display_prompt();

This method displays a test prompt for user cup selection.  It returns the selected value and does not test if it is valid.

=cut

sub display_prompt {
    my $self = shift;

    print " Select your move (1A,1B..): ";
    my $input = <>;

    unless ( $input ) {
        print "\n";
        return undef;
    }

    chomp $input;

    return undef unless $input;

    if ( $input =~ m/^[1-9][a-zA-Z]$/ ) {
        my ( $row ) = $input =~ m/(\d)/;
        my ( $cup ) = $input =~ m/(\D)/;
        
        my $choice = 0;
        foreach ( 'A' .. uc $cup ) { $choice ++ }
        return [ int $row, $choice ];
    }

    return undef;
}

=back

=cut

##
#
# BEGIN PRIVATE FUNCTIONS
#
##

##
# Returns an array ref containing
# the number of stones in each cup
# existing in $side from left to
# right.
##

sub _retrieve_stone_count {
    my $side = shift;

    # retrieve the first cup
    my $cup = $side -> {objects} -> {first_cup}
        || die "side is empty, remember to run create() on it\n";
    # retrieve the last cup
    my $last_cup = $side -> {objects} -> {goal_cup};

    # retrieve the stone counts
    my @stones;

    do {
        push @stones, $cup -> stones();
        $cup = $cup -> next();
    } until ( $cup == $last_cup -> next() );

    return \@stones;
}

##
# Returns a display of cups knowing
# given an array of stones in each
# cup, displayed left to right.
##

sub _display_horiz_side {
    my @stones = @_;

    my $f = '  ___   'x@stones. "\n".
        ' /   \  'x@stones. "\n";
    foreach my $s ( @stones ) {
        $s =~ s/^(.)$/ $1/;
        $f .= "| $s  | ";
    }
    $f .= "\n". ' \___/  'x@stones;

    return $f;
}

##
# Returns a game board divider
# for horizontal display.
##

sub _display_horiz_div {
    my $stones = shift;

    my $f = '--------'x$stones;

    return $f;
}

##
# Returns a display of cups in
# a vertical manner, knowing a
# given array of stones in each
# cup.  Displays top to bottom.
##

sub _display_vert_side {
    my @stones = @_;

    my $f;

    foreach my $s ( @stones ) {
        $s =~ s/^(.)$/ $1/;
        $f .= '  ___   '. "\n";
        $f .= ' /   \  '. "\n";
        $f .= "| $s  | ". "\n";
        $f .= ' \___/  '. "\n";
    }

    return $f;
}

1;
