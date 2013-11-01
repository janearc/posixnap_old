package PuzzleSolver::Snafooz::Solver;

use strict;
use warnings;
use Clone qw/clone/;

use vars qw/$VERSION @ISA/;

@ISA = qw//;
$VERSION = 0.01;

=head1 NAME

PuzzleSolver::Snafooz::Solver - A snafooz puzzle solver

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Snafooz::Solver;

 my $s = PuzzleSolver::Snafooz::Solver -> new();

 $s -> solve( \@pieces );

 my @solutions =
    @{ $s -> get_solutions() };
 
 $s -> display_solution( $solutions[0] );

=head1 ABSTRACT

This is a Snafooz puzzle solver.  It has the ability to find solutions for a simple 6-piece Snafooz cube as well as any other puzzle based on L<snafooz pieces|PuzzleSolver::Snafooz::Piece>.

=head1 METHODS

The following methods are provided:

=over 4

=item my $s = PuzzleSolver::Snafooz::Solver -E<gt> new();

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    # the solver is built around this.  i would like
    # to find a way to make this easily customizable
    # to allow for solving any puzzle with any number
    # of pieces
    my $solution = [
        { piece => undef, no_rotate => 1, cons => { } },
        { piece => undef, no_rotate => 0,cons =>
            { 3 => "0.1" } },
        { piece => undef, no_rotate => 0, cons =>
            { 0 => "0.2", 1 => "1.2" } },
        { piece => undef, no_rotate => 0, cons =>
            { "rev_1" => "0.3", 2 => "2.3" } },
        { piece => undef, no_rotate => 0, cons =>
            { "rev_2" => "0.0", 1 => "1.0", 3 => "3.0" } },
        { piece => undef, no_rotate => 0, cons =>
            { 0 => "2.2", "rev_1" => "1.1", 2 => "4.0", 3 => "3.3" } },
    ];

    return bless {
        objects => {
            permut => [ ],
            permuti => undef,
            pieces => [ ],
            solution => $solution,
            solutions => [ ],
            debug => undef,

        },
    }, $this;
}

=item $s -E<gt> build_fit_db( \@pieces );

This method stores piece fit information inside each piece object to be used later.

=cut

sub build_fit_db {
    my $self = shift;
    my @pieces;
    while ( @_ ) {
        map { push @pieces, $_ } @{ shift() };
    }
    #my @pieces = @{ shift() };
    # foreach piece
    foreach my $piece ( @pieces ) {
        $piece -> {objects} -> {fit} = {};
        $piece -> {objects} -> {reverse_fit} = {};
        # foreach side of that piece
        foreach my $side ( @{ $piece -> sides() } ) {
            $piece -> {objects} -> {fit} -> {$side -> serial()} = [];
            $piece -> {objects} -> {reverse_fit} -> {$side -> serial()} = [];
            # foreach other piece
            foreach my $not_piece ( @pieces ) {
                unless ( $piece -> serial()
                        == $not_piece -> serial() ) {
                    # foreach side of the other pieces
                    foreach my $not_piece_side ( @{ $not_piece -> sides() } ) {
                        if ( $side -> fit( $not_piece_side ) ) {
                            push @{ $piece -> {objects} -> {fit} -> {$side -> serial()} },
                                $not_piece_side -> serial();
                        }
                        if ( $side -> reverse_fit( $not_piece_side ) ) {
                            push @{ $piece -> {objects} -> {reverse_fit} -> {$side -> serial()} },
                                $not_piece_side -> serial();
                        }
                    }
                }
            }
        }
    }

    return \@pieces;
}

=item $s -E<gt> begin_permute( \@pieces );

This method prepares this solver to permute through all the pieces.  See next_permute().

Note: something in the permute process corrupts the solver in an unknown way.  Do not run the permute methods on a solver object which will later be used for C<solve()> or C<solve_simple()>.

=cut

sub begin_permute {
    my $self = shift;
    my $pieces = shift();

    $self -> {objects} -> {pieces} = $pieces;
    $self -> {objects} -> {permuti} = 0;
    $self -> _permute( [ 0 .. @{$pieces}-1 ], [] );

    1;
}


=item @pieces = @{ $s -E<gt> next_permute() };

This method returns a collection of pieces.  It is used for finding all the possible combinations of pieces that can be made by flipping them over.  Calling this method repetedly will always return a different set of pieces made from the original set, until all combinations have been used.  begin_permute() must be called first.

=cut

sub next_permute {
    my $self = shift;

    my $pi = $self -> {objects} -> {permuti};
    die "begin_permut() must be called first\n"
        unless defined $pi;

    return
        unless defined $self -> {objects} -> {permut} -> [$pi];

    my $pieces = clone( $self -> {objects} -> {pieces} );
    my @flips = @{ $self -> {objects} -> {permut} -> [$pi] };

    foreach my $i ( @flips ) {
        $pieces -> [$i] -> rev();
    };

    $self -> {objects} -> {permuti}++;

    return $pieces;
}

=item $s -E<gt> solve( \@pieces, $solution );

This method will attempt to solve the puzzle given by an array of pieces.  Optionally, you can supply a solution structure which will dictate the physics of the puzzle.  If no solution is given, this will attempt to solve for the default 6 piece cube.

This solver takes into account all flips of a piece as well as rotations.

=cut

sub solve {
    my $self = shift;
    my @pieces = @{ shift() };
    my @solution = @{ shift() || $self -> {objects} -> {solution} };
    my $debug = $self -> {objects} -> {debug};

    # unset the list of solutions
    $self -> {objects} -> {solutions} = [];

    # there cannot be a solution if there are
    # too many or too few pieces
    return
        unless @pieces == @solution;

    # prepare the flips
    $self -> begin_permute( \@pieces );

    # for each flip, call the simple solver
    while ( my $ps = $self -> next_permute() ) {

        print "*** new permut ***\n" if $debug;

        # test if a puzzle is solvable in the given
        # configuration by verifying that every
        # side connects to atleast one side of
        # another piece
        $self -> build_fit_db( $ps );
        if ( _check_connects( $ps ) ) {
            print "can solve\n" if $debug;
            # attempt to solve the puzzle here
            $self -> solve_simple( $ps, \@solution );
        } else {
            print "cannot solve\n" if $debug;
        }
    }

    return 1;
}

=item $s -E<gt> solve_simple( \@pieces, $solution );

This method is similar to C<solve()> but does not take flips into account, only rotations.  It also skips several heuristics which shrink the search space.  Generally you always want to use C<solve()> unless you have something devious in mind.

=cut

sub solve_simple {
    my $self = shift;

    # retrieve unplaced pieces
    my @unplaced_pieces = @{ shift() };
    # assume default solution if none given
    my $solution = shift() || $self -> {objects} -> {solution};
    # assumed no placed pieces if none given
    my @placed_pieces = @{ shift() || [ ] };

    # depth will be 0 if none given
    my $depth = shift || 0;
    my $debug = $self -> {objects} -> {debug};

    print "solve_simple $depth\n" if $debug;
    $self -> display_solution_simple( $solution ) if $debug;

    # is all pieces are placed, save the solution and exit
    if ( @unplaced_pieces == 0 ) {
        push @{ $self -> {objects} -> {solutions} }, $solution;
        return;
    }

    # find the starting place
    my $loc = @placed_pieces;

    # if no pieces are placed, place the one with
    # the fewest connections
    if ( $loc == 0 ) {
        # XXX: solve() does some good tests that should
        # be done when @placed_pieces is 0
        # build_fit_db has probably been called on these
        # pieces by solve(), but make sure

        $self -> build_fit_db( \@unplaced_pieces )
            unless $unplaced_pieces[0] -> {objects} -> {fit};

        # find the index of the piece with the fewest connections
        my $i = _least_connections( \@unplaced_pieces );

        $solution -> [$loc] -> {piece} = $unplaced_pieces[$i];
        @placed_pieces = splice @unplaced_pieces, $i, 1;

        # recurse
        $self -> solve_simple( \@unplaced_pieces, $solution, \@placed_pieces );
    } else {
        my $sol = $solution -> [$loc];
        my $connections = $sol -> {cons};

        # foreach unplaced piece
        foreach my $p ( 0 ..  @unplaced_pieces-1 ) {
            my $serial = $unplaced_pieces[$p] -> serial();

            # test if no_rotate
            my $ub = 4;
            if ( $sol -> {no_rotate} )
                { $ub = 1 }

            # foreach side, this only runs once if no_rotate
            foreach my $i ( 1 .. $ub ) {

                # the number of places this piece fits
                my $fit = 0;

                # test the piece for each required connection
                foreach my $c ( keys %{ $connections } ) {

                    # check if its a reverse fit
                    my $rev = grep { /rev_/ } $c;

                    # get the piece to fit (ptf) and various
                    # information about it
                    my $ptf = $connections -> {$c};
                    my ( $ptf_index ) = $ptf =~ m/^(.)/;
                    my ( $ptf_side ) = $ptf =~ m/(.)$/;
                    my $ptf_piece = $solution -> [$ptf_index] -> {piece};
                    my $ptf_serial = $ptf_piece -> serial();

                    # finally get the piece we'r testing
                    my $piece = $unplaced_pieces[$p];

                    # display the specific fit test
                    print "f:", $piece -> serial(), "->$c",
                        ":", $ptf_piece -> serial(), "->$ptf_side\n"
                            if $debug;

                    # test for reverse fit
                    if ( $rev ) {
                        my ( $temp ) = $c =~ m/rev_(.)/;
                        if ( $piece -> side($temp) -> reverse_fit(
                                $ptf_piece -> side($ptf_side) ) )
                            { $fit++ }
                        elsif ( $debug ) { print "no fit\n" }
                    # test for normal fit
                    } else {
                        if ( $piece -> side($c) -> fit(
                                $ptf_piece -> side($ptf_side) ) )
                            { $fit++ }
                        elsif ( $debug ) { print "no fit\n" }
                    }
                }

                # display result of all fit tests for each piece
                print "\tfit:$fit\n" if $debug;

                # if the piece fits in all required places (0 if no connections)
                if ( $fit == keys %{ $connections } ) {
                    print "placing piece $serial in loc $loc\n" if $debug;

                    # copy everything important to send into recursion
                    my $pp = clone( \@placed_pieces );
                    my $up = clone( \@unplaced_pieces );
                    my $s = clone( $solution );

                    # pull out the fitted piece and place it in
                    my ( $piece ) = splice @{ $up }, $p, 1;
                    push @{ $pp }, $piece;
                    $s -> [$loc] -> {piece} = $piece;

                    # recurse
                    $self -> solve_simple( $up, $s, $pp, $depth+1 );
                }

                # rotate right once unless no_rotate
                $unplaced_pieces[$p] -> rotate()
                    unless ( $ub == 1 );
            }
        }
    }
}

=item $s -E<gt> get_solutions();

This method returns an arrayref of all the solutions found while running C<solve()>.  This will return an empty arrayref if no solutions exist.

=cut

sub get_solutions {
    my $self = shift;
    return $self -> {objects} -> {solutions};
}

=item $s -E<gt> display_solution( $solution );

This method displays the contents of any one solution returned by C<get_solutions()>.  It visually outputs the snafooz pieces in the orientation specified by the solution.

=cut

sub display_solution {
    my $self = shift;
    my @s = @{ shift() };

    foreach ( 0 .. @s-1 ) {
        my @p = split "\n", $s[$_] -> {piece} -> to_string();

        # add the piece serial
        my @tag;
            # top
        @tag = split " ", $p[1];
        $tag[2] = "*";
        $p[1] = join " ", @tag;
            # bottom
        @tag = split " ", $p[3];
        $tag[2] = "*";
        $p[3] = join " ", @tag;
            # serial
        @tag = split " ", $p[2];
        $tag[1] = "*";
        $tag[3] = "*";
        $tag[2] = $s[$_] -> {piece} -> serial();
        $p[2] = join " ", @tag;

        # print it
        print "    Place $_\n";
        print "---------------\n";
        foreach ( @p ) {
            print "| $_ |\n";
        }
        print "---------------\n";
    }
}

=item $s -E<gt> display_solution_simple( $solution );

This method displays the contents of any one solution returned by C<get_solutions()>.  It essentially prints each piece in its given orientation.  It does not attempt to visually represent pieces.

=cut

sub display_solution_simple {
    my $self = shift;
    my @s = @{ shift() };

    foreach my $i ( 0 .. @s-1 ) {
        if ( $s[$i] -> {piece} ) {
            print "piece $i: ",
                $s[$i] -> {piece} -> serial(),
                " rotated clockwise ",
                $s[$i] -> {piece} -> rot_count(),
                " times and flipped ",
                $s[$i] -> {piece} -> rev_count(),
                " times\n";
        }
    }
}

=back

=cut

##
# This tests a group of pieces and
# returns true if each side can
# connect to atleast one other side
# of a different piece.
##

sub _check_connects {
    my @pieces = @{ shift() };

    return 1 unless @pieces == 6;

    foreach my $p ( @pieces ) {
        my $s = $p -> serial();
        foreach my $i ( 0 .. 3 ) {
            return unless (
                @{ $p -> {objects} -> {fit} -> {"$s.$i"} } > 0 );
        }
    }

    return 1;
}

##
# This method finds the piece with
# the least number of possible
# connections and returns its location
# in the argument array.
##

sub _least_connections {
    my @pieces = @{ shift() };

    my $best = { loc => undef, conns => undef };
    foreach ( 0 .. @pieces-1 ) {
        my $s = $pieces[$_] -> serial();
        my $conns = 0;
        foreach my $i ( 0 .. 3 ) {
            $conns +=
                @{ $pieces[$_] -> {objects} -> {fit} -> {"$s.$i"} };
            $conns +=
                @{ $pieces[$_] -> {objects} -> {reverse_fit} -> {"$s.$i"} };
        }
        if ( (! $best -> {loc} ) or $conns < $best -> {conns} ) {
            $best -> {loc} = $_;
            $best -> {conns} = $conns;
        }
    }

    return $best -> {loc};
}

##
# This method generates all the flip
# permutations and stores them numerically.
# This should only be called by
# begin_permute().
##

sub _permute {
    my $self = shift;
    my @items = @{ shift() };
    my @perms = @{ shift() };
    push @{ $self -> {objects} -> {permut} }, \@perms;
    foreach my $i ( 0 .. @items ) {
        my @new_items = @items;
        my $item = splice @new_items, 0, $i;
        $self -> _permute( \@new_items, [ @perms, $item ] )
            if $item;
    }
}

1;
