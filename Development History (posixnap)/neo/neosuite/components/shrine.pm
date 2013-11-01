use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_hours( 4 + rand(1) );
    if ( main::_runtime() ) {
        print main::_stamp(), " visiting shrine:\n";
        print "- ", $main::heap -> {neo} -> {ColtzansShrine} -> visit(), "\n";
    }

    $disp -> delay( \&run => $delay );
}
