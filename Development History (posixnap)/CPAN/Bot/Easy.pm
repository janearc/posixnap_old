package Bot::Easy;

use warnings;
use strict;
use POE qw{ Component::IRC Session };

my @children;
my ($nick, $server, $port, $channels);

sub import {
	my $class = shift;
	croak 'Syntax: use '.$class.' qw{ nick server port $channels };'
		unless @_ = 4;
	($nick, $server, $port, $channels) = @_;
}

POE::Component::IRC -> new( 'BotEasyPCI' ) 
	or croak 'Hurfle! Could not instantiate P::C::I';

POE::Session -> create( {
	inline_states => {
		_start => { 
			my ( $kernel, $heap ) = @_[KERNEL, HEAP];
			$kernel -> alias_set( 'BotEasy' );
		}

		BEregister => {
			my ( $kernel, $heap ) = @_[KERNEL, HEAP];
			my ( $childName ) = $_[ARG0];
			push @children, $childName;
		}
	}
} );

1;
