package Orchid;

use POE qw{ Session };

POE::Session -> create ( 
	inline_states => {
		_start => sub {
			my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
			$kernel -> alias_set( 'OrchidParent' );
		},
	}
);

# This is a holdover from Petunia. Please be gentle.
package utility;

POE::Session -> create (
	inline_states => {
		_start => sub {
			my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
			$kernel -> alias_set( 'LegacyParent' );
		},

		spew => \&spew,
		privateSpew => \&private_spew,
		publicSpew => \&public_spew,

	}
)

sub spew { 
	my ($thismsg, $thischan, $thisuser) = @_[ ARG0, ARG1, ARG2 ];
	my ($self, $bot) = @_[ OBJECT, SENDER ];

	# This was a public message
	if (defined $thischan) { 
		public_spew( @_ );
		return;
	}
	
	# This was a private message
	if (defined $thisuser and not defined $thischan) {
		private_spew( @_ );
		return;
	}
	return;
}

sub private_spew { 
	my ($thismsg, $thischan, $thisuser) = @_[ ARG0, ARG1, ARG2 ];
	my ($self, $bot) = @_[ OBJECT, SENDER ];

	$bot -> privmsg( $thisuser, $thismsg );

	return;
}

sub public_spew {
	my ($thismsg, $thischan, $thisuser) = @_[ ARG0, ARG1, ARG2 ];
	my ($self, $bot) = @_[ OBJECT, SENDER ];

	$bot -> privmsg( $thischan, $thismsg );

	return;
}

1;
