package Mancala::Display::Simple;

use strict;
use warnings;
use Data::Dumper;
use Exporter;

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_display/;
%EXPORT_TAGS = (
    'checks' => [qw/_test_display/]
);

=head1 NAME

Mancala::Display::Simple - A Mancala display object

=head1 SYNOPSIS

 # create a display object and use it
 use Mancala::Display::Simple;

 my $display = Mancala::Display::Simple -> new();
 $display -> display_board( $board_ref );
 $display -> display_score( $board_ref );
 $display -> display_prompt();

=head1 ABSTRACT

This is the super class for all Mancala display objects.  It is not designed to be used directly and will not function.  This is only a template to be inherited by other forms of Mancala displays.

=head1 METHODS

The following methods are available:

=over 4

=item $display = Mancala::Display::Simple -E<gt> new( %args );

This method returns a Mancala::Display::Simple object.  %args is a hash of initial values.  The required values are detailed in the sub classes.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    die "new() takes name => value pairs\n"
        unless ( @_ % 2 == 0 );

    my ( %args ) = @_;

    return bless {
        'objects' => { },
    }, $this;
}

=item $display -E<gt> display_board( $board_ref );

This method takes a reference to a L<Mancala::Board|Mancala::Board> or compatable object.  It attempts to display the board.  This method requires the board be fully constructed.  This method always returns trye.

See L<Mancala::Board>.

=cut

sub display_board {
    return 1;
}

=item $display -E<gt> display_prompt();

This method displays a prompt accepting user input and returns a user-selected value.  It does not perform any validity checks on the input.

=cut

sub display_prompt {
    return undef;
}

=item $display -E<gt> display_score( $board_ref );

This method displays the current game score based on the number of stones in each player's goal cup.

=cut

sub display_score {
    return undef;
}

=item $display -E<gt> display_final_score( $board_reg );

This method is similar to C<display_score()> but is tailored to the end of the game.  This can display a winning player as well as a basic score.

=cut

sub display_final_score {
    return undef;
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retvalue = _test_display( $display );

This method performs a sanity check on the value C<$display>.  It returns true if C<$display> is a L<Mancala::Display::Simple|Mancala::Display::Simple> or compatable object.  On a negative, this method C<die>s.

=cut

sub _test_display {
    my $display = shift;
    return 1
        if ref $display
            and $display -> can( 'display_board' )
            and $display -> can( 'display_prompt' )
            and $display -> can( 'display_score' );
    die "\$display must be a display object\n";
}

=back

=cut

1;
