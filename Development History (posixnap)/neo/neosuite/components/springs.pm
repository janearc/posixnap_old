use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_minutes( 31 + rand(5) );
    if ( main::_runtime() ) {
        print main::_stamp(), " visiting healing springs:\n";
        print "- ", $main::heap -> {neo} -> {HealingSprings} -> heal(), "\n";
    }

    $disp -> delay( \&run => $delay );
}
