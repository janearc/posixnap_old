package Orchid::Component::Joiner;

=head1 NAME

Orchid::Component::Joiner

=cut

=head1 ABSTRACT

A simple Orchid component for joining a channel upon init.

=cut

use warnings;
use strict;

use Data::Dumper;

=head1 SYNOPSIS

	use Orchid::Component::Joiner;
	my $joiner = Orchid::Component::Joiner -> new( Channels => [ qw{ #posix #bots } ] );

=cut

=head1 METHODS

=item new()

  my $joiner = Orchid::Component::Joiner -> new( Channels => [ qw{ #bots } ] );

The Joiner component is a simple module that does one thing: join a
channel upon initialization. There is no support for doing anything
after the initial join is performed.

Simply pass the names of the channels you would like joined as the
value to a C<Channels> key in the constructor, the module will handle
the rest.
	

=cut

sub new { 
  my $self = shift;
	# XXX: construct a hash of our arguments, this will die if we assign it
	# an uneven number of arguments.
  my %args = %{ { @_ } };

	my $channels = $args{channels};

  return bless { 
    # Pieces of our object are constructed here.
		Channels => [ @{ $channels } ],
  }, $self;

}


1;

=head1 LICENSE

You should have received a license with this software. If you did
not, please remove this software entirely, and contact the author,
Alex Avriette - alex@posixnap.net.

=cut

__END__
