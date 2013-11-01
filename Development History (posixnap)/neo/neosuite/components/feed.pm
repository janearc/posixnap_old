use strict;
use warnings;

sub run {
    my $disp = ${ shift() };

    my $delay = main::_hours( 3 + rand(1) );
    if ( main::_runtime() ) {
        print main::_stamp(), " feeding pets at soup kitchen\n";

        my @pets = @{ $main::heap -> {neo} -> {Pet} -> lookup_user_pets( 
            $main::heap -> {neo} -> {Common} -> username() ) };

        foreach my $pet ( @pets ) {
            while ( $main::heap -> {neo} -> {SoupKitchen} -> feed( $pet ) )
                { print "- feeding ", $pet -> name(), "\n" }
            print "- ", $pet -> name(), " is no longer hungry\n";
        }
    }

    $disp -> delay( \&run => $delay );
}
