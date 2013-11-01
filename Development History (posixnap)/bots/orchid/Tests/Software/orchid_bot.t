#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use Data::Dumper;
# This may seem contrived, but we do this to avoid the annoying
# "you didn't call run, you tard" warning.
use POE; POE::Kernel -> run(); 
use Bot::Pluggable;

# XXX: This needs to be fixed. There should be no need
# for hardcoded paths here.
use lib '../..'; 

use Orchid::Config;
use Orchid::Bot;

my $globalConfig = Orchid::Config -> new( 'testBot.xml' );
my @namespaces = $globalConfig -> namespaces();

# Test 1
ok( @namespaces == 3, " multiple configs" );

my @botArmy;
my @bpBots;

foreach my $config (@namespaces) {
	my $orchidBot = Orchid::Bot -> new( $config );
	push @botArmy, $orchidBot;
}

foreach my $orchidBot (@botArmy) {
	ok( my $bpBot = Bot::Pluggable -> new(
		Modules => [@{ $orchidBot -> modules() -> {names} }],
		Objects => [@{ $orchidBot -> modules() -> {objects} }],
		Nick => $orchidBot -> nick(),
		Server => $orchidBot -> server(),
		Port => $orchidBot -> port(),
	), " ".$orchidBot -> nick() );
}

# Sorry, couldn't resist.
ok( 1, " Boom." );
