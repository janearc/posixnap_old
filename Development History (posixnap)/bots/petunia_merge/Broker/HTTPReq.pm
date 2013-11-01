package Broker::HTTPReq;

#
# HTTPReq.pm
#
# Class for simple HTTP requests. This is to prevent submodules
# from having to undergo the drudgery of all the HTTP:: and LWP::
# modules. Thin down that codebase, baybee!
#

use strict;
use warnings;

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Headers;
use Data::Dumper;

our %cached_get = (
	page => "",
	epoch => 0,
	url => "",
);
# time in seconds
our $CACHE_TIMEOUT = 30;
our @AGENTS = ();
our $MAX_AGENTS = 16;

sub new {
	# we use some caching here because these objects tend to be rather large
	# and we really dont want to create too many.
	if ($#AGENTS > $MAX_AGENTS) {
		return ${ shift @AGENTS };
	}

	my $self = shift; # we return this last.
	my ( $args ) = @_;

	my $useragent = $args -> {useragent};
	my $debug = $args -> {debug};

	my $ua = LWP::UserAgent -> new( );
	my $content  = HTTP::Message -> new( );

	# by default we pretend to be MSIE 5.2 for MacOS X. If the
	# user has a preference, we issue it.
	if (! $useragent ) {
		$content -> header( 'UA-CPU' => 'PPC' );
		$content -> header( 'UA-OS' => 'MacOS' );
		$content -> user_agent( 'Mozilla/4.0 (compatible; MSIE 5.22; Mac_PowerPC)' );
	}
	else {
		# they have given us a preference
		$content -> user_agent( $useragent );
	}

	# this is stuff most browsers send, independant of agent.
	$content -> header( 'Extension' => 'Security/Remote-Passphrase' );
	$content -> header( 'Accept' => '*/*' );
	$content -> header( 'Accept-Language' => 'en' );
	$content -> header( 'Pragma' => 'no-cache' );

	# set a proxy if $ENV{PROXY} is set
	if ( $ENV{PROXY} ) {
		$ua -> proxy( [ 'http' ], $ENV{PROXY} );
	}

	my $agent = bless {
		objects => {
			ua => $ua,
			content => $content,
			debug => $debug,
		}
	}, $self;
	
	push @AGENTS, \$agent;
	return $agent;
}

# get()
# return content from a web request with an optional referer.
sub httpreq_get {
	my $self = shift;

	# get the url and optinal referrer
	my $url = shift;
	my $referer = shift;

	# retrieve user agent and content
	my $ua = $self ->  {objects} -> {ua};
	my $content = $self -> {objects} -> {content};
	my $debug = $self -> {objects} -> {debug};

	# make a request object with the url and headers from $content
	my $request = HTTP::Request -> new ( GET => $url, ${ $content -> clone() }{_headers} );
	# set the referer if given
	$referer and $request -> referer ( $referer );

	# get the resulting response
	# try 3 times
	my $response;
	for ( 1 .. 3 ) {
		$debug and utility::debug( "debug message: '$_ : \$response = \$ua -> request ( \$request )'" );
		$response = $ua -> request ( $request );
		if ( $response -> is_success() ) {
			$cached_get{page} = $response -> content();
			$cached_get{epoch} = time();
			$cached_get{url} = $url;
			return $response -> content();
		}
	}
	$debug and utility::debug( "debug message: '\$response = \$ua -> request ( \$request ) failed 3 times'" );
	return undef;
}

# cached_get()
# request a cached page so we don't hammer the server, and we take less time.
# returns the content.
sub httpreq_cached_get {
	my $self = shift;
	my $url = $_[0]; # we need to preserve @_
	my $now = time();
	if ( (($now - $CACHE_TIMEOUT) < $cached_get{epoch}) and $cached_get{url} eq $url) {
		return $cached_get{page};
	}
	else {
		return $self -> httpreq_get( @_ );
	}
}
