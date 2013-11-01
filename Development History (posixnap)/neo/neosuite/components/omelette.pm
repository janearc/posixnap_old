use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_hours( 5 + rand(1) );
    if ( main::_runtime() ) {
        print main::_stamp(), " getting a piece of the omelette:\n";
        print "- ", $main::heap -> {neo} -> {Omelette} -> get(), "\n";
    }

    $disp -> delay( \&run => $delay );
}
