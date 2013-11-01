package Neopets::Agent;

use constant NAME => 0;
use constant VALUE => 1;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use Neopets::Debug;
use Neopets::URL;

use vars qw{ @ISA $VERSION };

# time in seconds
our $CACHE_TIMEOUT = 30;
# tries before giving up
our $FETCH_RETRIES = 2;
# debug flag
our $DEBUG = 0;

@ISA = qw{ };
$VERSION = 0.1;

=head1 NAME

Neopets::Agent - An agent for fetching html for
use in Neopet software

=head1 SYNOPSIS

  # creating and using an agent to fetch urls

  use Neopets::Agent;

  my $agent = Neopets::Agent -> new();

  my $url = 'http://www.neopets.com';
  my $referer = 'http://www.neopets.com';

  my $page = $agent -> get(
      { url => $url,
        referer => $referer,
      } );

=head1 ABSTRACT

This module is part of the Neopets:: library, designed to allow scripting
of the neopets website and features ( http://www.neopets.com ).  This module
allows the user to create an Agent object for use in retrieving pages from
the neopets website.  Currently, only OO programming is allowed with this
module.

This module requires that a variable NP_HOME be set in order to function.
This should be the path to a writable directory in which this toolkit
can store information.

=head1 METHODS

The following methods are provided:

=over 4

=item $agent = Neopets::Agent->new;

The constructor takes arguments in hash form.
Available arguments are:

  cookiefile => $path
      This is relative to $ENV{NP_HOME} and
      defaults to 'cookies.txt' if not given.

  debug => 1
      This sets a debug flag within the
      module, effecting function.

  useragent => $useragent
      See LWP::UserAgent for information
      on setting this.

  cache_timeout => $seconds
      This adjusts the default timeout
      for old cached pages, usually 30
      seconds.

  fetch_retries => $retries
      Changes the default number of
      retries when a page was not
      retrieved correctly, usually 2.

  no_events => $bool
      Normally the agent checks for
      "Something has happened!"
      events.  This will disable
      that functionality by avoiding
      creating a Neopets::Event object.

  event => $event_obj_ref
      If you do infact want events
      enabled, you can pass it your
      own Neopets::Event object and
      it will not create one of its
      own.

  no_checks => $bool,
      This turns off the regular
      sanity checks.  It is useful
      for squeezing speed out of
      the module.

=cut

sub new {
    my $that = shift; # we return this last.
    my $this = ref( $that ) || $that;
    my ( $args ) = @_;

    # get arguments
    my $useragent = $args -> {useragent};
    my $cookiefile = $args -> {cookiefile} || 'cookies.txt';
    $DEBUG = $args -> {debug};
    my $events = undef;
    unless ( $args -> {no_events} ) {
        unless ( $events = $args -> {event} ) {
            require Neopets::Event;
            $events = \Neopets::Event -> new({ debug => $DEBUG, agent => $this });
        }
    }
    my $sanity_checks = (! $args -> {no_checks});

    # reset module constants if necessary
    if ( $args -> {cache_timeout} ) {
        $CACHE_TIMEOUT = $args -> {cache_timeout} }
    if ( $args -> {fetch_retries} ) {
        $FETCH_RETRIES = $args -> {fetch_retries} }

    if ( not $ENV{NP_HOME} ) {
        # user doesnt have NP_HOME set, no cookies, no soup for you.
        die "$0: new: bailed out. set \$NP_HOME or we cannot use cookies.\n";
    }

    # XXX: matt: for some reason these tests are ineffective on my machine
    if ( ( not -d $ENV{NP_HOME} ) or ( not -w $ENV{NP_HOME} ) ) { 
        # the $NP_HOME directory does not exist
        die "$0: new: bailed out. \$NP_HOME directory does not exist or is not writable.\n";
    }

    my $ua = LWP::UserAgent -> new( );
    my $content  = HTTP::Message -> new( );

    # by default we pretend to be MSIE 5.2 for MacOS X. If the
    # user has a preference, we issue it.
    if (! $useragent ) {
        $content -> header( 'UA-CPU' => 'PPC' );
        $content -> header( 'UA-OS' => 'MacOS' );
        $content -> user_agent( 'Mozilla/4.0 (compatible; MSIE 5.22; Mac_PowerPC)' );
    } else { # they have given us a preference
        $content -> user_agent( $useragent );
    }

    # this is stuff most browsers send, independant of agent.
    $content -> header( 'Extension' => 'Security/Remote-Passphrase' );
    $content -> header( 'Accept' => '*/*' );
    $content -> header( 'Accept-Language' => 'en' );
    $content -> header( 'Pragma' => 'no-cache' );

    # neopets prefers this.
    $content -> content_type( 'application/x-www-form-urlencoded' );

    # retrieve or create cookie file
    debug( "using cookiefile: '".$ENV{NP_HOME}."/$cookiefile'" );
    my $cookie_jar = HTTP::Cookies -> new(
        File     => $ENV{NP_HOME}."/$cookiefile",
        AutoSave => 1,
    );

    # set the cookies in the ua for use later
    $ua -> cookie_jar( $cookie_jar );

    # set a proxy if $ENV{PROXY} is set
    if ( $ENV{PROXY} ) {
        $ua -> proxy( [ 'http' ], $ENV{PROXY} ) }

    my $cache = { };
    my @event_list = qw//;

    return bless {
        objects => {
            ua => $ua,
            content => $content,
            cache => $cache,
            events => $events,
            event_list => \@event_list,
            sanity_checks => $sanity_checks,
        },
    }, $this;
}

=item $page = $agent -> get();

This method retrieves a web page
via the GET method and takes hash
ref arguments:

  url => $url
      the url to fetch
  
  referer => $referer
      the referer

  no_cache => $boolean
      do not return a cached version
      of the page

  params => $hashref
      a hashref representing name =>
      value keys for cgi parameters

  content => $page
      substitute $page for any
      content that would normally be
      retrieved.  no retrieval is done.
      when using this, specify a $url
      as this method will still attempt
      to cache the page.  this is mainly
      for testing purposes.

This returns the html contents of the
requested page or undef if request
failed.  This method tries several
times (see constructor: fetch_retries)
before returning an undef value.

=cut

sub get {
    my $self = shift;
    my ( $args ) = @_;

    # get arguments
    my $url = $args -> {url};
    my $referer = $args -> {referer};
    my $no_cache = $args -> {no_cache};
    my $params = $args -> {params};
    my $page_content = $args -> {content};

    # retrieve user agent, content, and cache
    my $content = $self -> {objects} -> {content};
    my $cache = $self -> {objects} -> {cache};
    my $events = $self -> {objects} -> {events};
    
    # build a url from the $params
    $url = _build_url( $url, $params );

    # check if allowed to fetch from cache
    unless ( $no_cache or $page_content ) {
        # if a recent page is in cache, return the cached version
        if ( my $page = _check_cache( $cache, $url ) ) { return $page }
    }

    # if content is specified, check it in and return it
    # this is only for testing purposes
    if ( $page_content ) {
        $cache -> {$url} =
            { page => $page_content, epoc => time(), };
        ${ $events } -> check( $page_content ) if $events;
        return $page_content;
    }

    # make a request object with the url and headers from $content
    my $request = HTTP::Request -> new ( GET => $url, ${ $content -> clone()}{_headers} );
    # set the referer if given
    $referer and $request -> referer ( $referer );

    # get the resulting response
    # try 3 times
    my $response;
    debug( "get: getting '$url'" );
    for ( 0 .. $FETCH_RETRIES ) {
        if ( my $page = _make_request( $self, $request ) ) {
            return $page;
        }
    }

    # if something goes wrong, we end up here
    # return undef
    debug( "get: failed " . ($FETCH_RETRIES+1) . " times, giving up" );
    return;
}

=cut $page = $agent -> post();

This method reacts similar to the
get() function but uses the POST
method instead of GET.

It is assumed that any user using
this method wants data sent as well
as retrieved.  This will never
cache a page.

=cut

sub post {
    my $self = shift;
    my ( $args ) = @_;

    # get arguments
    my $url = $args -> {url};
    my $referer = $args -> {referer};
    my $params = $args -> {params};
    my $page_content = $args -> {content};

    # post only works if it has arguments
    # use get() in this case
    debug ( "differing to get()")
        and return $self -> get( @_ )
        unless ( keys %{ $params } );

    # retrieve content, and cache
    my $content = $self -> {objects} -> {content};
    my $cache = $self -> {objects} -> {cache};
    my $events = $self -> {objects} -> {events};
    
    # use a trick with _build_url to get
    # a param string
    my $param_string = _build_url( "", $params );
    $param_string =~ s/^.//;

    # make a request object with the url and headers from $content
    my $request = HTTP::Request -> new ( POST => $url, ${ $content -> clone()}{_headers} );
    # set the referer if given
    $referer and $request -> referer ( $referer );
    # set the arguments
    $request -> content( $param_string );

    # get the resulting response
    # try 3 times
    debug( "POSTing '$url'" );
    for ( 0 .. $FETCH_RETRIES ) {
        if ( my $page = _make_request( $self, $request ) ) {
            return $page;
        }
    }

    # if something goes wrong, we end up here
    # return undef
    debug( "POST failed " . ($FETCH_RETRIES+1) . " times, giving up" );
    return undef;
}

# build a url out of params

sub _build_url {
    my $url = shift;
    my $params = shift || return $url;

    $url .= "?";
    foreach my $key ( keys %{ $params } ) {
        if ( my $value = $params -> {$key} )
            { $url .= "$key=$value&" }
        else
            { $url .= "$key=&" }
    }
    $url =~ s/&$//;

    return $url;
}

# check if a page is in cache and
# return it if it is

sub _check_cache {
    my $cache = shift;
    my $url = shift;

    if ( $cache -> {$url} and ((time() - $CACHE_TIMEOUT) < $cache -> {$url} -> {epoc}) ) {
        debug( "get: fetching page from cache" );
        return $cache -> {$url} -> {page};
    } else {
        return undef;
    }
}

# makes a request

sub _make_request {
    my $self = shift;
    my $request = shift;

    # retrieve information
    my $ua = $self -> {objects} -> {ua};
    my $events = $self -> {objects} -> {events};
    my $sanity_checks = $self -> {objects} -> {sanity_checks};

    my $response = $ua -> request ( $request );

    # this will see if lwp was sent a forward request
    # and GET it if found
    # i don't like this but it is a limitation of
    # lwp et al.
    if ( (! $response -> {_headers} -> {content} )
            and my $file = $response -> {_headers} -> {location} ) {
        my $content = $self -> {objects} -> {content};
        my $referer = $request -> {_headers} -> {referer};
        my $url = $request -> url();
        $url =~ s/[^\/]+$//;
        $url .= "/$file";
        $request = HTTP::Request -> new ( GET => $url, ${ $content -> clone()}{_headers} );
        $referer and $request -> referer( $referer );
        return _make_request( $self, $request );
    }

    if ( $response -> is_success()
            and my $page = $response -> content() ) {
        # check if the site is down unless sanity checks are disabled
        if ( ( $sanity_checks and $self -> running( $page ) )
                or ( ! $sanity_checks ) ) {
            # cache information
            debug( "get: page retrieved, caching" );
            ${ $events } -> check( $page ) if defined $events;
            return $page;
        }
    }
}

=item $agent -> cache( { url => $url, page => $page } );

This method caches a page for retrieval
later.

=cut

sub cache {
    my $self = shift;
    my ( $args ) = @_;

    my $cache = $self -> {objects} -> {cache};

    my $url = $args -> {url};
    my $page = $args -> {page};

    if ( $url and $page ) {
        $cache -> {$url} =
            { page => $page, epoc => time(), };
    }

    1;
}

=item my $running = $agent -> running( $page );

This method takes a page and returns
true if the page is good.  The only
time this method returns false is if
it detects the page to be a 'down for
maintenance' Neopets page.

=cut

sub running {
    my $self = shift;
    my $page = shift;

    return ! ( $page =~ /Neopets is down for maintenance/ );
}

1;

=head1 SUB CLASSES

None.

=head1 COPYRIGHT

Copyright 2002

Neopets::* are the combined works of Alex Avriette and
Matt Harrington.

Matt Harrington <narse@underdogma.net>
Alex Avriette <avriettea@speakeasy.net>

The perl5.5 vs perl < 5.5 build process is stolen with
permission from sungo and the POE team (poe.perl.org),
mostly verbatim.

I suppose we should thank the Neopets people too for
making such a thoroughly enjoyable site. Maybe one day
they will make a text interface for their site so we
wouldnt have to code an API around the LWP:: and 
HTTP:: modules, but probably not. Until then...

=head1 LICENSE

Please see the enclosed LICENSE file for licensing information.

=cut
