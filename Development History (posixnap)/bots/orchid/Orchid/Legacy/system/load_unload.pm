sub parse {
    my ($thischan, $thisuser, $thismsg) = (@_);
    return unless my ($act, $mod) = $thismsg =~ /^:((?:un|re)?load)\s+(\S+)/;
    if ($act eq "load") {
	if( utility::load_module( $mod ) ) {
	    utility::spew( $thischan, $thisuser, "loading of $mod succeeded" );
	}
	else {
	    utility::spew( $thischan, $thisuser, "loading of $mod failed" );
	}
	return 1;
    }
    elsif ($act eq "unload") {
	utility::unload_module( $mod );
	utility::spew( $thischan, $thisuser, "attempted to unload $mod" );
	return 1;
    }
    # JZ: extras
    elsif ($act eq "reload") {
	utility::unload_module( $mod );
	utility::load_module( $mod );
	utility::spew($thischan, $thisuser, "attempted to reload $mod");
	return 1;
    }
    return 0;
}

sub public {
    parse( @_ );
}

sub private {
    parse( @_ );
}

sub emote {
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, 
		":[load|unload] [modulename] - load or unload a module. don't mess with this." );
}

1;
