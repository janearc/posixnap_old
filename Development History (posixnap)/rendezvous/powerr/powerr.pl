#!/usr/bin/perl

use warnings;
use strict;

use Carp;
use Pod::Usage;
use Data::Dumper;
use Carp::Assert;
use Getopt::Long;
use Powerr::Config;
use POE qw{ Wheel::Run Session };

# TODO: Command line arguments
my $mDNSProxyResponder = '../mDNSPosix/build/prod/mDNSProxyResponder';
my $config = Powerr::Config -> new( 'powerr.conf' );

POE::Session -> create(
	inline_states => {
		_start				=> \&_start,
		check_config	=> \&check_config,
	},
	heap => {
		Config => $config,
		Wheels => [ ],
	}
);

$poe_kernel -> run();
carp "Exiting normally.\n";
exit 0;

sub _start {
	my ($kernel, $heap) = @_[ KERNEL, HEAP ];

	assert( $heap -> {Config} );

	my %commands;
	foreach my $service ($config -> services()) {
		$commands{ $service -> {Service} } = [ 
			$mDNSProxyResponder, 
			$service -> as_string(),
		];
	}

	assert( keys %commands > 0 );

	push @{ $heap -> {Wheels} },  POE::Wheel::Run -> new(
		Program => $commands{$_},
		ErrorEvent => 'oops',
		CloseEvent => 'closed',
	) for keys %commands;
}

