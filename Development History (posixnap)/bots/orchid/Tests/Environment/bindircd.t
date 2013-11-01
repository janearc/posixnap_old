#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

our $ORCHID_HOME = $ENV{ORCHID_HOME};
our $PERL = $ENV{PERL};

use IO::Socket;

# check to see if our environment is marginally happy
my ($listener, $talker, $text);
ok( $listener = IO::Socket::INET -> new (
			Listen    => 5,
			LocalAddr => 'localhost',
			LocalPort => 6667,
			Proto     => 'tcp'
		), " bound to port 6667" );
ok( $talker = IO::Socket::INET -> new (
			PeerAddr => 'localhost', 
			PeerPort => 6667, 
			Proto    => 'tcp'
		), " connected to port 6667" );
ok( $talker -> send('wibble'), " sent data" );
ok( $listener -> accept(), " accepted connection" );
ok( $listener -> recv( $text, 128 ), " grabbed text" );
ok( $text eq 'wibble', " got what we expected" );

