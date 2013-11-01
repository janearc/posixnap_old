package Rubix::Side;

use strict;
use warnings;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    return bless {
        objects => {
            data => { },
        },
    }, $this;
}

sub set {
    my $self = shift;
    $self -> {objects} -> {data} = shift;
}

sub get {
    my $self = shift;
    return $self -> {objects} -> {data};
}

sub get_tile {
    my $self = shift;
    my $x = shift;
    my $y = shift;
    return $self -> {objects} -> {data} -> {$x} -> {$y};
}

sub remove_stickers {
    my $self = shift;
    my @stickers;
    foreach my $x ( 1 .. 3 ) {
        foreach my $y ( 1 .. 3 ) {
            push @stickers, $self -> get_tile( $x, $y ) -> remove_sticker();
        }
    }
    return \@stickers;
}
        

1;

