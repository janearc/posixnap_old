package Orchid::Bot;

=head1 NAME

Orchid::Bot

=cut

=head1 ABSTRACT

A class for maintaining individual Orchid bot objects, data,
configurations, etc.

=cut

use warnings;
use strict;

use Data::Dumper;
use Orchid::IdentityBroker;

my $dataStore = Orchid::IdentityBroker -> new ( Bots => { } );

=head1 SYNOPSIS

	use Orchid::Bot;
	my $bot = Orchid::Bot -> new( $config );

=cut

use POE qw{ Session Component::IRC };

=head1 METHODS

=item new()

my $orchidBot = Orchid::Bot -> new( $config );

Orchid allows multiple flavors of bots and listeners to be used. As
such, a simple bot class was created to abstract these methods from
the API. A developer can feel safe in creating bots from the 
Orchid::Bot class, and know that inside the module itself, all is
well.

The new() method would prefer a C<$config> object from the Orchid::Config
class.

=cut

sub new { 
  my $self = shift;
  my @args = @_;

	# Argument #1 is our configuration from the XML file.
	my $config = shift @args;

  my $child = bless { 
    # Pieces of our object are constructed here.
		Config => $config,
		Serial => '', 
  }, $self;

	# Instantiate a token for us in the data store
	$child -> {Serial} = $dataStore -> obtainIdentity( $child );

	return $child;

}

=item _spawn()

=cut

sub _spawn {
	my $self = shift;
	my @args = @_;

	# POE::Session::create() returns a reference to the session
	# that was created. See the perldoc there for more info.
	# Note, PC::IRC has to talk to these states. Are we sure that's
	# happening here?
	return POE::Session -> create( 
		package_states => [ "Orchid::Bot::Backend" => [ qw{
			_start
			_stop
			irc_001
			irc_disconnected
			irc_socketerr
			irc_error
			irc_public
		} ] ],
		inline_states => {
			OrchidBotYield => \&yield,
		},
		args => [ \$self ]
	);
}

=item privmsg()

  $orchidBot -> privmsg( '#posix', 'I like pie!' );
	$orchidBot -> privmsg( 'sungo', 'PANTS' );

This method causes the bot to send a message to the indicated
channel or user. If this is confusing, please consult the IRC
RFC, RFC1459.

=cut

sub privmsg {
	my $self = shift;
	$self -> {Kernel} -> post( @{ $self -> PCIidentity() }, 'privmsg', @_ );
}

=item joinChannel()

  $orchidBot -> joinChannel( '#posix' );

C<joinChannel()> (so named to avoid conflicts with perl's C<join> 
function) causes the bot to join the channel provided as argument,
if it is able to.

=cut

sub joinChannel {
	my $self = shift;
	$self -> {Kernel} -> post( @{ $self -> PCIidentity() }, 'join', @_ );
}

=item yield()

  $orchidBot -> yield( 'part', '#posix' );

C<yield()> allows you to post an event to the session that the bot
you are using is attached to. The session data is stored inside the
IdentityBroker, and a token allows Orchid::Bot to look up which 
session to post the event to. This is the preferred method of passing
events to the bot.

=cut

sub yield { 
	my $kernel	= $_[KERNEL];
	my $object	= $_[ARG0];
	my $state		= $_[ARG1];
	my @params	= @_[ARG2 .. $#_];
	$kernel -> post( $object -> parentIdentity(), $state, @params );
}


=item nick()

	print "Hello, my name is ".$orchidBot -> nick();

Simply returns the nick of the bot in question. No arguments.

=cut

sub nick { 
	return shift -> {Config} -> {server} -> {nick};
}

=item username()

	print "Attempting to assume username ".$orchidBot -> username();

Simply returns the username of the bot in question. No arguments.

=cut

sub username { 
	return shift -> {Config} -> {server} -> {username};
}

=item fullname()

	print "My name is ".$orchidBot -> fullname();

Simply returns the "full name" of the bot in question. No arguments.

=cut

sub fullname { 
	return shift -> {Config} -> {server} -> {fullname};
}

=item server()

	print "Attempting to connect to ".$orchidBot -> server();

Simply returns the hostname of the bot in question. No arguments.

=cut

sub server { 
	return shift -> {Config} -> {server} -> {hostname};
}

=item port()

	print "Ack! Could not reach port ".$orchidBot -> port();

Simply returns the port of the bot in question. No arguments.

=cut

sub port { 
	return shift -> {Config} -> {server} -> {port};
}

=item modules()

	my @modules = $orchidBot -> modules() -> {names};
	my @objects = $orchidBot -> modules() -> {objects};

Typically, the developer will not find a need to access these functions,
but they are provided should they be needed. C<modules()> returns an 
anonymous hash reference containing two keys, C<names> and C<objects>,
which refer to the names of the objects used and the objects they have
given our bot.

Historic note: this function exists to appease the Bot::Pluggable API.

=cut

sub modules { 
	my $modules = shift -> {Config} -> {modules} -> {module};
	my @moduleNames = keys %{ $modules };
	# Stuff goes here.
	my @moduleObjects = ( );
	return { names => [ @moduleNames ], objects => [ @moduleObjects ] };
}

=head1 METHODS USED BY THIS CLASS INTERNALLY

=cut

=item PCIidentity()

	$_[ KERNEL ] -> post( $orchidBot -> PCIidentity(), 'part', '#posix' );

In the event that you need to communicate with a bot's POE::Component::IRC
session, you may do so with this function. This is discouraged.

=cut

sub PCIidentity {
	return 'OrchidBotPoCoIRC_'.shift -> {Serial};
}

=item sessionIdentity()

	$_[ KERNEL ] -> post( $orchidBot -> sessionIdentity(), 'state', @args );

The C<sessionIdentity()> method returns the session which your bot is 
presently using. This method is discouraged.

=cut

sub sessionIdentity { 
	return [ shift -> {ID} ]
}

=item parentIdentity()

  $_[ KERNEL ] -> post( $orchidBot -> parentIdentity(), 'state', @args );

In rare cases, it may be necessary to request the identity of a particular
bot's parent session. This, too, is strongly discouraged.

=cut

sub parentIdentity {
	return 'OrchidBotParent_'.shift -> {Serial};
}

# Do we need this?
1;

package Orchid::Bot::Backend;

use POE qw{ Session Component::IRC };

sub _start { 
	my $kernel = $_[KERNEL];
	my $self = ${ $_[ ARG0 ] };
	my $parentIdentity = $self -> parentIdentity();
	$kernel -> alias_set( $parentIdentity );
	POE::Component::IRC -> new( $self -> PCIidentity() )
		or croak $self -> nick()." .. stillborn.";

  $kernel->post( $parentIdentity, 'register', 'all');
  $kernel->post( $parentIdentity, 'connect', { 
		Debug    => 1,
		Nick     => $self -> nick(),
		Server   => $self -> server(),
		Port     => $self -> port(),
		Username => $self -> username(),
		Ircname  => $self -> fullname(),
	} );

	# presently do not need this, right?
  # $kernel->sig( INT => "sigint" );
}


sub irc_public {
  my ($kernel, $sender, $inbound, $chan, $msg) = @_[KERNEL, SENDER, ARG0 .. ARG2];
  my ($who) = $inbound =~ m/^(.*)!.*$/ or die "malformed who: $1";
}

sub _stop {
  my ($kernel) = $_[KERNEL];
  print "Control session stopped.\n";
}


sub irc_001 {
  my ($kernel) = $_[KERNEL];
}

sub irc_disconnected {
  my ($server) = $_[ARG0];
  print "Lost connection to server $server.\n";
  $_[KERNEL]->post( "dicebot", "unregister", "all" );
}

sub irc_error {
  my $err = $_[ARG0];
  print "Server error occurred! $err\n";
}

sub irc_socketerr {
  my $err = $_[ARG0];
  print "Couldn't connect to server: $err\n";
}

1;

=head1 LICENSE

You should have received a license with this software. If you did
not, please remove this software entirely, and contact the author,
Alex Avriette - alex@posixnap.net.

=cut

__END__
