use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_hours( 4 + rand(1) );
    if ( main::_runtime() ) {
        print main::_stamp(), " collecting interest:\n";
        
        if ( $main::heap -> {neo} -> {Bank} -> collect_interest() )
            { print " - success\n" }
        else
            { print " - failed\n" }
    }

    $disp -> delay( \&run => $delay );
}
