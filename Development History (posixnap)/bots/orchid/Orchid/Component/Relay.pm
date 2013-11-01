package Orchid::Component::Relay;

=head1 NAME

Orchid::Component::Relay

=cut

=head1 ABSTRACT

A simple Orchid component for relaying information between two
Orchid::Bot objects.

=cut

use warnings;
use strict;

use Data::Dumper;

=head1 SYNOPSIS

	use Orchid::Component::Relay;
	my $relay = Orchid::Component::Relay -> new( 
		nameOfBotA => \$botA,
		nameOfBotB => \$botB,
		flow => {
			nameOfBotA => destination => nameOfBotB => "#perl",
			nameOfBotB => destination => nameOfBotB => "somebodysNick",
		},
	);

=cut

=head1 METHODS

=item new()

  my $relay = Orchid::Component::Relay -> new( #arguments# );

The Relay package is intended to provide a bridge between two separate
bot objects who would be inhabiting, for example, an IRC network. In
the example above, all traffic from #perl that is visible to BotA is
then relayed to the user owning 'somebodysNick', which is visible to
BotB.

The first arguments in the constructor should be hash keys to identify
the Bot objects being passed to it, and their values should be
references to the actual bot objects. Following this, should be a key
of 'flow', which in turn points to a hash reference which contains the
flow characteristics of the relay being constructed.

Flow characteristics should be defined as:

  [ a name of a bot referenced earlier in the constructor ]
	[ the string "destination" ]
	[ a name of a bot referenced earlier in the constructor ]
	[ where said messages should be directed ]

IRC allows us to send PRIVMSG commands to either channels or users.
This means that we don't have to make a distinction between the two. If
the destination is "#perl", messages will be sent to #perl, and all
users joined to that channel will see them. In the event it is
somebody's nick, all messages will be directed to that nick.

=cut

sub new { 
  my $self = shift;
	# XXX: construct a hash of our arguments, this will die if we assign it
	# an uneven number of arguments.
  my %args = %{ { @_ } };

	# extract the flow characteristics, everything else is a bot.
	my $flow = $args{flow};
	delete $args{flow};

  return bless { 
    # Pieces of our object are constructed here.
		Flow => $flow,
		Agents => { %args },
  }, $self;

}


1;

=head1 LICENSE

You should have received a license with this software. If you did
not, please remove this software entirely, and contact the author,
Alex Avriette - alex@posixnap.net.

=cut

__END__
