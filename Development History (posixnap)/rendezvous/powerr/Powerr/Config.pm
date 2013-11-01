package Powerr::Config;

use warnings;
use strict;
use Carp;
use Carp::Assert;
use File::Slurp;

sub new {
	my $class = shift;
	my $filename = shift;

	# Make sure it's here
	assert( -e $filename );

	my @file = 
		map { chomp and $_ } 
			grep { (length $_) > 1 and /^[^#]/ } 
				read_file( $filename );

	# Make sure they pass us in groups of four
	assert( not @file % 4 );

	my @services;
	while (@file) {
		push @services, Powerr::Config::Service->new( splice @file, 0, 4 );
	}

	return bless { Services => [ grep defined, @services ] }, $class;
}

sub services {
	my $self = shift;
	assert( ref $self->{Services} eq 'ARRAY' );
	return @{ $self->{Services} };
}

1;

package Powerr::Config::Service;

# ip        Real IP address (or valid host name) of the host 
#           where the service actually resides
# hostlabel First label of the dot-local host name to create 
#           for this host, e.g. "foo" for "foo.local."
# srvname   Descriptive name of service, e.g. "Stuart's Ink Jet Printer"
# srvtype   IANA service type, e.g. "_ipp._tcp" or "_ssh._tcp", etc.
# port      Port number where the service resides (1-65535)
# txt       Additional name/value pairs specified in service definition, 
#           e.g. "pdl=application/postscript"

use Carp;
use Carp::Assert;
use Sys::Hostname;

my $host = hostname();

my @columns = qw{ IPAddr ServiceName ServiceType Port HostLabel };

sub new {
	my $class = shift;

	my ($srvname, $srvtype, $ip, $port) = @_;

	assert( $srvname and $srvtype and $ip and $port );

	return bless {
		IPAddr => $ip,
		ServiceName => $srvname,
		ServiceType => $srvtype,
		Port => $port,
		HostLabel => $host."-powerr.local",
	}, $class;
}

sub as_string {
	my $self = shift;
	warn 
	join $", @{ $self }{@columns};
}

1;
