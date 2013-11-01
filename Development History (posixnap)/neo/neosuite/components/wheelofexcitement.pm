use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_minutes( 120 + rand(60) );
    if ( main::_runtime() ) {
        print main::_stamp(), " spinning wheel of excitement:\n";
        print "- ", $main::heap -> {neo} -> {WheelOfExcitement} -> spin(), "\n";
    }

    $disp -> delay( \&run => $delay );
}
