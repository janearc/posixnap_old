#!/usr/bin/perl -w

use strict;
use POE;
use POE::Component::IRC;
use Data::Dumper;
use Carp qw{ cluck carp croak };


my $nick = 'theo';

my @theo_quotes = (
	"Write more code.",
	"Make more commits.",
	"That's because you have been slacking.",
	"slacker!",
	"That's what happens when you're lazy.",
	"idler!",
	"slackass!",
	"lazy bum!",
	"Stop slacking you lazy bum!",
	"slacker slacker lazy bum bum bum slacker!",
	"I could search... but I'm a lazy bum ;)",
	"sshutup sshithead, ssharpsshooting susshi sshplats ssharking assholes.",
	"Lazy bums slacking on your asses.",
	"35 commits an hour? That's pathetic!",
	"Fine software takes time to prepare.  Give a little slack.",
	"emacs on the vax",
	"Just a minute ago we were hugging and now you, guys, do not love me anymore",
	"I'll let you know when I need to floss my teeth",
	"If you can't figure out yourself, you're lacking some mental faculties",
	"I am just stating a fact",
	"blah blah",
	"i'd love to hack, but i can't",
	"Wait, yes, I am on drugs",
	"during release it is a constant.  almost noone helps.",
	"i let you guys do whatever you wanted",
	"you bring new meaning to the terms slackass. I will have to invent a new term.",
	"if they cut you out, muddy their back yards",
	"Make them want to start over, and play nice the next time.",
	"It is clear that this has not been thought through.",
	"avoid using abort().  it is not nice.",
	"if you do not test that, you are banned from editing theo.c",
	"That's the most ridiculous thing I've heard in the last two or three minutes!",
	"I'm not just doing this for crowd response. I need to be right.",
	"i admit you are better than i am...",
	"I'd put a fan on my bomb.. And blinking lights...",
	"I love to fight",
	"I am not concerned with commit count",
	"No sane people allowed here.  Go home.",
	"you have to stop peeing on your breakfast",
	"feature requests come from idiots",
	"henning and darren / sitting in a tree / t o k i n g / a joint or three",
	"KICK ASS. TIME FOR A JASON LOVE IN!  WE CAN ALL GET LOST IN HIS HAIR!",
);

sub _start {
  my ($kernel) = $_[KERNEL];

  $kernel->alias_set( 'theo' );
  $kernel->post( 'theo', 'register', 'all');
  $kernel->post( 'theo', 'connect', { Debug    => 1,
					 Nick     => $nick,
					 Server   => $ARGV[0] ||
					             'irc.posixnap.net',
					 Port     => $ARGV[1] || 6667,
					 Username => 'theo deraadt',
					 Ircname  => "theo deraadt", }
	       );
}

sub irc_001 {
  my ($kernel) = $_[KERNEL];

  $kernel->post( 'theo', 'mode', $nick, '+i' );
  $kernel->post( 'theo', 'join', '#posix' );
  $kernel->post( 'theo', 'privmsg', '#posix', 'One remote hole, in nearly six years!' );
  $kernel->post( 'theo', 'topic', '#posix' );
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
  $kernel->call( 'theo', 'quit', 'http://www.openbsd.org/' );
}

sub irc_public {
  my ($kernel, $who, $chan, $msg) = @_[KERNEL, ARG0 .. ARG2];
  $who =~ s/^(.*)!.*$/$1/ or die "Weird-ass who: $who";

  if ($msg =~ /^$nick!/i) {
  	$kernel->post( 'theo', 'privmsg', $chan, "$who: ".$theo_quotes[ rand @theo_quotes ] );
	}
}


POE::Component::IRC->new( 'theo' ) or
  die "Can't instantiate new IRC component!\n";
POE::Session->new( 'main' => [qw(_start _stop irc_001 irc_disconnected
                                 irc_socketerr irc_error irc_public)] );
$poe_kernel->run();

%SIG = map { 
	my $sig = $_;
	( $_ => $sig eq "INT" ? 
		sub {
			croak;
		}
		:
		sub { 
			$poe_kernel->post( 'theo', 'privmsg', '#posix', "ack, received SIG$sig" );
		}
	)
} keys %SIG;

exit 0;
