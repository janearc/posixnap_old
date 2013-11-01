use strict;
use warnings;

sub init {
    require Neopets;
    
    print main::_stamp(), " loading all neopets modules\n";

    $main::heap -> {neo} = Neopets -> new({all => 1})
        || die;

    print " - success\n";
}

sub run { }
