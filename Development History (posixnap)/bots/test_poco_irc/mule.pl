#!/usr/bin/perl -w

use strict;
use POE;
use POE::Component::IRC;
use Data::Dumper;
use Carp qw{ cluck carp croak };

sub _start {
  my ($kernel) = $_[KERNEL];

  $kernel->alias_set( 'testbot' );
  $kernel->post( 'testbot', 'register', 'all');
  $kernel->post( 'testbot', 'connect', { 
		Debug    => 1,
		Nick     => 'testbot',
		Server   => 'irc.posixnap.net',
		Port     => '6667',
		Username => 'testbot',
		Ircname  => 'testbot', 
	} );
}

sub irc_001 {
  my ($kernel) = $_[KERNEL];

  $kernel->post( 'testbot', 'join', '#testing' );
  $kernel->post( 'testbot', 'privmsg', '#testing', 'waiting.' );
}

sub irc_disconnected {
  my ($server) = $_[ARG0];
  print "Lost connection to server $server.\n";
}

sub irc_error {
  my $err = $_[ARG0];
  print "Server error occurred! $err\n";
}

sub irc_socketerr {
  my $err = $_[ARG0];
  print "Couldn't connect to server: $err\n";
}

sub _stop {
  my ($kernel) = $_[KERNEL];

  print "Control session stopped.\n";
  $kernel->call( 'testbot', 'quit' );
}

sub irc_public {
  my ($kernel, $fqun, $thischan, $thismsg) = @_[KERNEL, ARG0 .. ARG2];
  my ($thisuser) = $fqun =~ m/^(.*)!.*$/;
	die "$fqun malformed" unless $thisuser;
	if (my ($count) = $thismsg =~ /iterate\s+(\d+)/) {
		foreach (1 .. $count) {
			$kernel -> post( 'testbot', 'privmsg', '#testing', "iteration $_: ".time() );
		}
	}
	elsif ($thismsg =~ /ping\?/) {
		$kernel -> post( 'testbot', 'privmsg', '#testing', 'pong '.time() );
	}
}


POE::Component::IRC->new( 'testbot' ) or
  die "Can't instantiate new IRC component!\n";
POE::Session->new( 'main' => [qw(_start _stop irc_001 irc_disconnected
                                 irc_socketerr irc_error irc_public)] );
$poe_kernel->run();

exit 0;
