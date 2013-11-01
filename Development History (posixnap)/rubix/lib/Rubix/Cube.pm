package Rubix::Cube;

use strict;
use warnings;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    return bless {
        objects => {
            sides => [ ],
        }
    }, $this;
}

sub set {
    my $self = shift;
    $self -> {objects} -> {sides} = shift();
}

sub sides {
    return shift() -> {objects} -> {sides};
}

sub done {
    my $self = shift;
    foreach my $s ( @{ $self -> {objects} -> {sides} } ) {
        my $color = $s -> get_tile(1, 1) -> sticker() -> color();
        foreach my $x ( 1 .. 3 ) {
            foreach my $y ( 1 .. 3 ) {
                return unless
                    $s -> get_tile($x, $y) -> sticker() -> color()
                        eq $color;
            }
        }
    }

    return 1;
}
        

1;
