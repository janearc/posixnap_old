#!/usr/bin/perl

use warnings;
use strict;

use Bot::Pluggable;
use POE;

# Our modules
use Orchid::Config;
use Orchid::Bot;

# Let's snarf the commandline argument or just use a default here.
my $globalConfig = Orchid::Config -> new( shift || 'orchidConfig.xml' );

# Let's make sure we have a place to store our little army of bots
our @Bots;

foreach my $config ( $globalConfig -> namespaces() ) {

	my $orchidBot = Orchid::Bot -> new( $config );

}

$poe_kernel -> run();
