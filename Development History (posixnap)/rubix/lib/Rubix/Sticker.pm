package Rubix::Sticker;

use strict;
use warnings;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    return bless {
        objects => {
            color => $args{color} || die "Rubix::Sticker::new requires a color argument\n",
        },
    }, $this;
}

sub color {
    return shift() -> {objects} -> {color};
}

1;
