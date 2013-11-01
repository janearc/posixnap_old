use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_minutes( 30 + rand(15) );
    if ( main::_runtime() ) {
        print main::_stamp(), " attempting to steal from snowager:\n";
        print "- ", $main::heap -> {neo} -> {Snowager} -> steal(), "\n";
    }

    $disp -> delay( \&run => $delay );
}
