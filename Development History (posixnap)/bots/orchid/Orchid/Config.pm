package Orchid::Config;

=head1 NAME

Orchid::Config

=cut

=head1 ABSTRACT

A class for providing configuration data to the Orchid hierarchy of
modules.

=cut

use warnings;
use strict;

use File::Slurp;
use XML::Simple;
use Data::Dumper;

# You could change this if you really wanted to.
use constant ROOT => 'Orchid'; 

=head1 SYNOPSIS

	use Orchid::Config;
	my $config = Orchid::Config -> new( $filename );

=cut

=head1 METHODS

=item new()

my $config = Orchid::Config -> new( "myUberConfig.xml" );

Developers are expected to pass the C<new()> method the name of
an XML file which can be properly parsed by the expat library.
Note you may have to pass an absolute pathname.

=cut

sub new { 
  my $self = shift;
  my @args = @_;

	# Argument #1 is our filename
	my $file = shift @args;

	# Snarf our xml.
	my $xs = XML::Simple -> new();
	my $xml = $xs -> XMLin( $file );

  return bless { 
    # Pieces of our object are constructed here.
		XML => $xml,
  }, $self;

}

=item namespaces()

my @namespaces = $config -> namespaces();

The Orchid framework allows us to instantiate several personalities
from one config file. It is necessary, then, to be able to address
each of them separately. So we might see something like this:

	use Orchid::Bot;
	use Orchid::Config;
	
	my $config = Orchid::Config -> new( "./twoBots.xml" );
	my @namespaces = $config -> namespaces();
	my @botArmy;
	foreach my $personality (@namespaces) {
		my $orchidBot = Orchid::Bot -> new( $personality );
		push @botArmy, $orchidBot;
	}

Through this methodology, the developer is able to maintain firm 
separation of each bot personality, while still having access to all
the configuration data necessary for each.

=cut

sub namespaces {
	my $xml = shift -> {XML};
	my @configs;

	# Aww, we have a little botArmy.
	if (ref($xml -> {config}) eq "ARRAY") {
		@configs = @{ $xml -> {config} };
	}
	else {
		@configs = ( $xml -> {config} );
	}

	# XXX: I'd like input on whether this should actually be returning 
	# an arrayref instead of an array.
	return @configs; 
}

=item splort()

my $xml = $config -> splort();

This is for debugging purposes only and will be removed, probably. 
the splort method simply prints the xml that was stored in the
config. So you'd most likely want to do something like:

	print $config -> splort();

Of course you could use a serializer or do something wacky if you
really wanted to, but don't expect this one to stick around.

=cut

sub splort {
	return Dumper( shift -> {XML} );
}

1;

=head1 LICENSE

You should have received a license with this software. If you did
not, please remove this software entirely, and contact the author,
Alex Avriette - alex@posixnap.net.

=cut

__END__
