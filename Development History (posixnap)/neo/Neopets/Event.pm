package Neopets::Event;

use strict;
use warnings;

use Neopets::Debug;

use vars qw{ @ISA $VERSION };

# event flag
our $EVENTS = 0;
# event list
our @EVENT_LIST = qw//;
# debug flag
our $DEBUG = 0;

@ISA = qw{ };
$VERSION = 0.1;

=head1 NAME

Neopets::Event - A random event handler

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=item $event = Neopets::Event->new;

The constructor takes arguments in hashref form.
Available arguments are:

=cut

sub new {
    my $that = shift; # we return this last.
    my $this = ref( $that ) || $that;
    my ( $args ) = @_;

    # get arguments
    $DEBUG = $args -> {debug};

    return bless {
        objects => {
        },
    }, $this;
}

=item $event = $event -> check( $page );

This method checks a page for events.  If
events are found, the Neopets::Events::EVENTS
flag is raised.  Events can be retrieved
via the $events-> get() method.

=cut

sub check {
    my $self = shift;
    my $page = shift;

    fatal( 'requires page' )
        unless ( $page );

    if ( $page =~ /Something has happened/
        or $page =~ /Random Event/ ) {
        # XXX appearently this doesn't match everthing...
        # adding a temporary file
        my ( $event ) = $page =~ m!Something has happened.*?(<.*?)</table>!si;
        $event ? ( ) : ( $event ) = $page =~ m!Random Event.*?(<.*?)</table>!si;
        # clean tags
        $event =~ s/<.*?>//g;
        unless ( $event ) {
            use File::Slurp;
            append_file('event_log.txt', time().$page );
        }
        #`echo $page >> events.html`;
        $self -> add( $event );
    }

    return $EVENTS;
}

=item $event -> add( $event );

This method adds an event to the queue
where $event is a string.

=cut

sub add {
    my $self = shift;
    my $event = shift;

    # mebbe this isn't good
    $event =~ s/<.*?>//g;
    push @EVENT_LIST, $event;
    $EVENTS++;
}

=item @events = @{ $event -> get() };

This method returns all events stored in
the agent.  By default the agent will
store any events it finds.  If `no_events'
was specified on object construction, this
will not be done.  Instead the user can
manually use $agent -> check_events( $page )
to test if a page contains an event.  This
is not recommended.

=cut

sub get {
    my $self = shift;
    return \@EVENT_LIST;
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
