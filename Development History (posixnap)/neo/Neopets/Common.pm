package Neopets::Common;

use strict;
use warnings;

use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Common - A module for commonly used methods

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=cut

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $common = Neopets::Common->new;

This constructor takes hash arguments and
returns a common object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  debug => $debug  (true or false)

=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
  my ( $args ) = @_;

  my $agent = $args -> {agent};
  $DEBUG = $args -> {debug};

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }

  return bless {
    objects => {
      agent => $agent,
    },
  }, $this;
}

=item $username = $common -> username();

This method returns the username
as represented by the login cookies.
If this function returns undef,
the user is most likely not logged in.

=cut

sub username {
    my $self = shift;

    my $agent = ${ $self -> {objects} -> {agent} };

    # get the username from the cookies
    my ( $name )
        = $agent -> {objects} -> {ua} -> {cookie_jar} -> as_string()
            =~ m/neoremember=([^;]+)/s;
    
    unless ( $name ) {
        debug( "username: no username found, make sure you are logged in" );
        return undef;
    }

    $name;
}

=item $neopoints = $common -> neopoints();

This method returns the quantity of neopoints
available to the user, as represented by their
inventory page. Note it returns an integer value,
NOT "14,543 NP".

=cut

sub neopoints {
    my $self = shift;

    # get the username from the cookies
    my $inventory_page = ${ $self -> {objects} -> {agent} } -> get( {
        url => 'http://www.neopets.com/objects.phtml?type=inventory',
        referer => 'http://www.neopets.com/objects.phtml?type=inventory',
        no_cache => 'what, me worry?', } );

    my ($np) = $inventory_page =~ m!<a href='/neopoints\.phtml'>([^<]+)</a>!;
    if (not defined $np) {
        debug( "neopoints: was not able to discern neopoints. are you sure you are logged in?" );
        return $np; # undef
    }

    # normalize
    $np =~ y/, //d;

    $np;
}

=item my $logged_in = $common -> $logged_in();

This method tests if a user is
logged into the Neopets site.

=cut

sub logged_in {
    my $self = shift;

    my $page = ${ $self -> {objects} -> {agent} } -> get (
        { url => 'http://www.neopets.com/objects.phtml',
          params => { type => 'inventory' },
          no_cache => 1, } );

    return 1
        unless $page =~ 'you are not logged in';

    return undef;
}

=item my @results = @{ $common -> search( $string ) };

This method searches for $string using
the Neopets search method.  Returns an
array of { value => $val, type => $type, url => $url }
hashes.

=cut

sub search {
    my $self = shift;
    my $string = shift
        || fatal( 'must supply search string' );

    my $page = ${ $self -> {objects} -> {agent} } -> post (
        { url => 'http://www.neopets.com/search.phtml',
          referer => 'http://www.neopets.com',
          params => { s => $string },
          no_cache => 1, } );
}


1;

=back

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
