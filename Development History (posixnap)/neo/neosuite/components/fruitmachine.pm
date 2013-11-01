use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_hours( 5 + rand(1) );
    if ( main::_runtime() ) {
        print main::_stamp(), " spinning fruit machine:\n";
        print "- ", $main::heap -> {neo} -> {FruitMachine} -> spin(), "\n";
    }

    $disp -> delay( \&fruit_machine_loop => $delay );
}
