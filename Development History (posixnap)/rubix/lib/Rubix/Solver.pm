package Rubix::Solver;

use strict;
use warnings;
use Clone qw/clone/;
use vars qw/$VERSION/;

$VERSION = 0.01;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    return bless {
        objects => {},
    }, $this;
}

sub solve {
    my $self = shift;
    my $c = clone( shift() );

    my @stickers;

    # remove all the stickers
    foreach my $s ( @{ $c -> sides() } ) {
        map { push @stickers, $_ }
            @{ $s -> remove_stickers() };
    }

    # sort all the stickers
    @stickers =
        sort{ $a -> color() cmp $b -> color() }
            @stickers;

    # reapply the stickers in better places
    foreach my $s ( @{ $c -> sides() } ) {
        foreach my $x ( 1 .. 3 ) {
            foreach my $y ( 1 .. 3 ) {
                $s -> get_tile( $x, $y ) -> add_sticker( pop @stickers );
            }
        }
    }

    if ( $c -> done() ) {
        return $c;
    } else {
        print "this cube is unsolvable\n";
        return;
    }
}

1;
