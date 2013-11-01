package Rubix::Tile;

use strict;
use warnings;
use Rubix::Sticker;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $color = $args{color} || die;
    my $sticker = Rubix::Sticker -> new(
        color => $color );

    return bless {
        objects => {
            sticker => $sticker,
        },
    }, $this;
}

sub sticker {
    return shift() -> {objects} -> {sticker};
}

sub remove_sticker {
    my $self = shift;
    my $s = $self -> {objects} -> {sticker};
    $self -> {objects} -> {sticker} = undef;
    return $s;
}

sub add_sticker {
    my $self = shift;
    $self -> {objects} -> {sticker} = shift;
    1;
}

1;
