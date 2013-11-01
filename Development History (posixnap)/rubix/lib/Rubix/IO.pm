package Rubix::IO;

$|++;

use strict;
use warnings;
use Rubix::Cube;
use Rubix::Side;
use Rubix::Tile;

sub new {
    bless { }, shift();
}

sub get_cube {
    my $self = shift;
    my $c = Rubix::Cube -> new();

    print <<EOF;

I will now take input on building a rubik's cube.  I will only
give you instructions once so listen up!

I will prompt you for input on each side.  If the cube is flat
on a table with one side facing you, this is the order of the
sides.

    1: facing you
    2: opposite
    3: right
    4: left
    5: top
    6: bottom

( like the order really matters here )

For each side I will ask for 9 colors starting with the top left
corner and readong right to left, top to bottom.

You can use whatever colors you feel like, and yes 'shoe' is a
valid color.  However, if you give me a null character, I will
be very angry.

EOF


    my @sides;
    foreach ( 0 .. 5 ) {
        my $s = { };
        print "Side ", $_+1, ":\n";
        foreach my $x ( 1 .. 3 ) {
            $s -> {$x} = { };
            foreach my $y ( 1 .. 3 ) {
                print "\tcolor: ";
                my $color = <>;
                $s -> {$x} -> {$y} = Rubix::Tile -> new( color => $color );
            }
        }
        $sides[$_] = Rubix::Side -> new();
        $sides[$_] -> set($s);
    }
    $c -> set( \@sides );

    return $c;
}

sub display_solution {
    print <<EOF;


A solution has been found.  Ok, this one is easy ready?

    Step 1: peel one sticker off the cube.  Any sticker
        will do (note: it helps to have long finger nails).
    Step 2: repeat Step #1 53 times.
    Step 3: sort the stickers by color.
    Step 4: reapply each color to the cube in order so that
        each color is on the same side of the cube.

    TADA!!!  You have successfully solved a Rubik's cube!

EOF
}

1;

