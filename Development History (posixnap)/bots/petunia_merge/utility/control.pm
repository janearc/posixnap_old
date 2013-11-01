package utility::control;

use warnings;
use strict;

use Carp;

use utility;
use utility::communication;

use POE;
use POE::Component::IRC;
use POE::Kernel;

# these subs are quick hacks, but are required for the 
# PoCo::IRC API. I should mail the author about this. (but still havent!)
sub irc_public {
	irc_msg_dispatch( "public", @_ );
	irc_msg_dispatch( "auth_pub", @_ );
}

sub irc_msg {
	irc_msg_dispatch( "private", @_ );
	irc_msg_dispatch( "auth_priv", @_ );
}

sub irc_part {
	irc_msg_dispatch( "part", @_ );
}

sub irc_join {
	irc_msg_dispatch( "Join", @_ );
	irc_msg_dispatch( "Join_auth", @_ );
}

sub irc_kick {
	irc_msg_dispatch( "kick", @_ );
}

# unified message handler
sub irc_msg_dispatch {
	# XXX: i hate this. we really should not have to pass our mode, we
	# should be able to discern it from our args.
	my $mode = shift;

	# make sure communication has our kernel.
	my $kernel = $_[KERNEL];
	$utility::communication::kernel ||= $kernel;

	my ($fqun, $dest, $thismsg) = @_[9 .. 11];
	# print map { "'$_'" } @_; die;
	# determine whether this went to a user or a channel
	my $thischan;
	if (ref $dest and $dest -> [0] =~ /#/) {
		$thischan = $dest -> [0];
	}
	else {
		$thischan = $dest;
	}

	# grab the username from the fqun
	my ($thisuser) = $fqun =~ /^([^!]+)!/
		or confess "$0: irc_msg_dispatch: \$who malformed: '$fqun'\n";
	
	my %dispatch = (
		public => { args => [ $thischan, $thisuser, $thismsg, $kernel ] },
		auth_pub => { args => [ $thischan, $fqun, $thismsg, $kernel ] },

		private => { args => [ "", $thisuser, $thismsg, $kernel ] },
		auth_priv => { args => [ "", $fqun, $thismsg, $kernel ] },

		# note caps. we use them because 'join' is a function already.
		Join => { args => [ $thischan, $thisuser, $thismsg, $kernel ] },
		Join_auth => { args => [ $thischan, $fqun, $thismsg, $kernel ] },

		part => { args => [ $thischan, $thisuser, $thismsg, $kernel ] },
		kick => { args => [ $thischan, $thisuser, $thismsg, $kernel ] }
	);

	# XXX: we use this line here to run the modules asynchronously 
	# utility::async::run_modules( $mode, $dispatch{$mode} -> {args} );


	# iterate over possible responses
	my %modules = %utility::modules;
	# XXX: async merge stuff. this line is what we use to iterate NON asynchronous modules
	# foreach my $mod (grep ! defined ${"$utility::modules{$_}::async"}, keys %modules) {
	foreach my $mod (keys %modules) {
		if (defined *{"$modules{$mod}\::$mode"}) {
			my $sub_ref = \&{"$modules{$mod}\::$mode"};
			$sub_ref -> ( @{ $dispatch{$mode} -> {args} } );
		}
	}
}

1;
