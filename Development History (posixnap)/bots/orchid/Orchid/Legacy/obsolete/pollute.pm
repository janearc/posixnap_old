use warnings;
use strict;

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, "No way am I letting you use this function, sunshine." );
}

sub do_pollute {
    my( $thischan, $thisuser, $thismsg ) = @_;

    # FIXME is the exclusion ([^\$`'%]) sufficient? 
    if (my( $key, $val ) = $thismsg =~
	    /^:pollute\s+(\w+)(?:=([^\$`'%]+))?/) {

	if( $2 ) {
	    if( not utility::is_maintainer( $thisuser ) ) {
		utility::spew( $thischan, $thisuser,
		    'no way, sunshine' );
		return 0;
	    } else {
		$utility::config{$key} = $val;
		Broker::EvilDBH -> notify(); # inform EvilDBH of our changes
	    }
	} else {
	    utility::spew( $thischan, $thisuser, "$key = ".$utility::config{$key} );
	}
	return 1;
    }

    else { return 0 }
}

sub do_notify { 
	my ( $thischan, $thisuser, $thismsg ) = (@_);
	if ( $thismsg eq ':notify' or $thismsg eq ':spank' ) {
		if ( utility::is_maintainer( $thisuser ) ) {
			Broker::EvilDBH -> notify();
			utility::spew( $thischan, $thisuser, 'again!' );
			return 1;
		}
		else {
			# im not sure why i chose to do it this way. blame the snot.
			my @responses = map { s/^\s+//g and $_ ? $_ : ()  } split /\n/, qq{
				uhhh?
				I dont swing that way, $thisuser...
				not a chance.
				as if.
				no way, sunshine.
				go spank yourself, $thisuser.
			};
			my $nothanks = $responses[ int rand $#responses + 1 ];
			utility::spew( $thischan, $thisuser, $nothanks );
			return 1;
		}
	}
	else {
		return 0;
	}
	return 0;
}

sub public {
    do_pollute( @_ );
		do_notify( @_ );
}

sub private {
    do_pollute( @_ );
		do_notify( @_ );
}

sub emote {
}

