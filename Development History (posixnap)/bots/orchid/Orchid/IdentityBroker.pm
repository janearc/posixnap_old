package Orchid::IdentityBroker;

=head1 NAME

Orchid::IdentityBroker

=cut

=head1 ABSTRACT

A horribly over-complicated module for brokering identity tokens to 
swarms of objects. Not intended for public consumption.

=cut

use warnings;
use strict;
use POE;

my %Tokens;
my %Serials;

# so we have a token that can evaluate to its session id, as well
# as to public message, private message, etc. this means that when
# we create the bot object, we have to create a token, and store it
# in the bot.

sub new {
	my $class = shift;
	die "Incorrect arguments passed to constructor" if $#_ % 2;
	my @stores;
	foreach my $store (keys %args) {
		push @stores, bless { Class => $store, Clients => [ ] }, $class;
	}
	if (@stores == 1) {
		return shift @stores;
	}
	else {
		return \@stores;
	}
}

sub obtainIdentity {
	my $self = shift;
	my $victim = shift;
	my $class = $self -> {Class};
	my $token = 'Orchid'. $victim -> server(). $victim -> nick(). _serial( $class );
	$Tokens{$class} -> {$token} = {
		ID => $poe_kernel -> ID_session_to_id( $victim -> _spawn() ),
		Object => $victim,
		Kernel => \$poe_kernel,
		Payload => [ ], # a sort of heap
		Class => $class,
	};
	$self -> {Serial} = $token;
}

sub deToken {
	my ($self, $object) = @_;
	my $oClass = $object -> {Class};
	my $bClass = $self -> {Class};
	warn "This identity broker ($bClass) did not spawn this object ($oClass)!"
		if $bClass ne $oClass;
	return $Tokens{$oClass} -> { $object -> {Serial} };
}


# XXX: This may be over-engineered.
sub _serial {
	my $class = shift;
	my $serial;
	if (not $Serials{$class}) {
		my $firstSerial = substr time, (length time) - 3, 3;
		$Serials{$class} = { $firstSerial => 1 };
		return $firstSerial;
	}
	else {
		do {
			$serial = substr time, (length time) - 3, 3;
		} until ( not $Serials{$class} -> {$serial} );
		$Serials{ $serial } = [ ];
		return $serial;
	}
}

1;
