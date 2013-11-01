package utility::communication;

use strict qw{ subs vars };
use warnings;

use POE;
use POE::Component::IRC;
use POE::Kernel;

use Carp;
use utility;

our $kernel;

sub public_spew {
	my ($thischan, $thisuser, $thismsg) = @_;
	return unless $thismsg;
	return unless defined $kernel;
	foreach my $l (split /\n/, $thismsg) {
		$kernel -> post( $utility::config{nick}, 'privmsg', $thischan,
			$l ? $l : ' ' ); # send a "blank" line
	}
}

sub private_spew {
	my ($thischan, $thisuser, $thismsg) = @_;
	return unless $thismsg;
	return unless defined $kernel;
	foreach my $l (split /\n/, $thismsg) {
		$kernel -> post( $utility::config{nick}, 'privmsg', $thisuser,
			$l ? $l : ' ' ); # send a "blank" line
	}
}

sub public_notice {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg;
	return unless defined $kernel;
	foreach my $l (split /\n/, $thismsg) {
		$kernel -> post( $utility::config{nick}, 'notice', $thischan,
			$l ? $l : ' ' ); # send a "blank" line
	}
}

sub private_notice {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg;
	return unless defined $kernel;
	foreach my $l (split /\n/, $thismsg) {
		$kernel -> post( $utility::config{nick}, 'notice', $thisuser,
			$l ? $l : ' ' ); # send a "blank" line
	}
}

sub spew {
	my ($thischan, $thisuser, $thismsg) = @_;
	return unless $thismsg;
	if ($thischan) {
		public_spew( @_ );
	}
	else {
		private_spew( @_ );
	}	
}

sub notice {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg;
	if ($thischan) {
		public_notice( @_ );
	}
	else {
		private_notice( @_ );
	}
}

1; 
