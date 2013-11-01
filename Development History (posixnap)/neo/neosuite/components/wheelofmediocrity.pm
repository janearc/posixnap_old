use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_minutes( 40 + rand(25) );
    if ( main::_runtime() ) {
        print main::_stamp(), " spinning wheel of mediocrity:\n";
        print "- ", $main::heap -> {neo} -> {WheelOfMediocrity} -> spin(), "\n";
    }

    $disp -> delay( \&run => $delay );
}
