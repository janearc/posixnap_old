package POE::Wheel::Dispatcher;

use constant MAX_THREADS => 1;
use constant MAX_DELAY => 1;

use strict;
use warnings;
use Data::Dumper;

use POE qw/ Wheel::Run Filter::Line/;

use vars qw/ $VERSION /;

$VERSION = 0.01;

=head1 NAME

POE::Dispatcher - Job dispatcher

=head1 SYNOPSIS

    # create a dispatcher object
    use POE::Loop::Dispatcher
    my $dispatcher = POE::Loop::Dispatcher -> new();

    # set two jobs to run in 5 seconds, args: 'bar', 'baz'
    $dispatcher -> delay( \&foo, 5, qw/bar baz/ );
    $dispatcher -> alarm( \&foo, time() + 5, qw/bar baz/ );

    # boot the dispatcher
    $dispatcher -> boot();

    exit;

    # test function
    sub foo { print "foo\n" }

=head1 ABSTRACT

This module simplifies setting job delays with POE.

=head1 METHODS

The following methods are provided:

=over 4
=cut

=item $dispatcher = POE::Loop::Dispatcher -> new();

This method takes hashref args and returns
a dispatcher object.  Optional hashref
arguments are:

  delay => $delay
The max interval in which to loop the
dispatcher.  The lower the number, the
better the timing of the dispatcher.
Decimals are allowable.

  max_thread => $threads
The maximum number of jobs to run at
any given time.

  forking => $bool
This sets the forking ability of the
dispatcher.  With forking, the dispatcher
runs jobs in a non-blocking way, but
jobs do not have the ability to change
the script data.  Without forking,
overlaping jobs must wait for others
to finish before executing.

=cut

our $KILL;

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;
    my ( $args ) = @_;

    my $delay = $args -> {delay} || MAX_DELAY;
    my $max_threads = $args -> {max_threads} || MAX_THREADS;
    my $forking = $args -> {forking};

    # [ { delay => $time, code => \&sub,  args => [ ] } ]
    my $functions = [ ];

    return bless {
        objects => {
            forking => $forking,
            running => undef,
            heap => undef,
            delay => $delay,
            max_threads => $max_threads,
            functions => $functions,
        }
    }, $this;
}

=item $dispatcher -> alarm( $coderef, $time, @args (optional) );

This method adds a job to be executed into the queue.
The time is in unix seconds (see time()) and args are
optional.

=cut

sub alarm {
    my $self = shift;

    my $functions = $self -> {objects} -> {functions};

    my $function = shift;
    my $time = shift;

    die 'alarm( \&function, $time, @args (optional )\n'
        unless ( $function and $time >= 0 );

    $time = int( $time );

    my @args = @_;

    push @{ $functions }, { delay => $time, code => $function, args => \@args };
        @{ $functions } = sort { $a ->{delay} <=> $b -> {delay} } @{ $functions };
}


=item $dispatcher -> delay( $coderef, $delay, @args (optional) );

This method adds a job to be executed into the queue.
The delay is in seconds and args are optional.  Partial
seconds are not allowed.

=cut

sub delay {
    my $self = shift;

    my $functions = $self -> {objects} -> {functions};

    my $function = shift;
    my $delay = shift;

    die 'delay( \&function, $delay, @args (optional )\n'
        unless ( $function and $delay >= 0 );

    $self -> alarm( $function => $delay + time() );
}

=item $dispatcher -> boot();

This method boots the dispatcher.  At this
point the dispatcher will take control and
not release it until all jobs are completed.

=cut

sub boot {
    my $self = shift;

    #warn "boot called while dispatcher was running\n"
    #    and return if $self -> {objects} -> {running};

    #$self -> {objects} -> {running} = 1;

    my @sessions = qw//;
    for ( 1 .. $self -> {objects} -> {max_threads} ) {
        $sessions[$_] = POE::Session -> create (
            inline_states => {
                _start => \&_start,
                _stop  => \&_stop,
                dispatcher => \&_dispatcher,
                dispatch => \&_dispatch,
                child_stdout => \&_child_stdout,
                child_stderr => \&_child_stderr,
                child_close => \&_child_close,
                event_sighup => \&_event_sighup,
            },
            heap => { dispatcher => \$self },
        );
    }

    $KILL = '';

    $poe_kernel -> run();
}

# dispatch, run a job
# should only be called by
# the _dispatcher

sub _dispatch {
    my ( $args ) = @_;
    my $code = $args -> {code};
    my $arguments = $args -> {args};
    my $dispatcher = $args -> {dispatcher};
    my $poe = $args -> {poe};

    return unless defined &{ $code };

    ref $arguments ?
        &{ $code }( $dispatcher, $poe, @{ $arguments } ) :
        &{ $code }( $dispatcher, $poe );
}

# dispatcher, runs in a loop
# called by poe -> delay()

sub _dispatcher {
    my $session = $_[SESSION];
    my $heap = $_[HEAP];
    my $self = ${ $heap -> {dispatcher} };

    if ( $heap -> {child} -> {$session->ID} ) {
        $_[KERNEL] -> delay_set( 'dispatcher', $self -> {objects} -> {delay} );
        return;
    }

    # test for queued jobs
    if ( @{ $self -> {objects} -> {functions} }
            or ( $heap -> {child} and %{ $heap -> {child} } ) ) {
        my $job;
        if ( $job = ${ $self -> {objects} -> {functions} }[0]
                and $job -> {delay} <= time() ) {

            # get code and args
            my $code = $job -> {code};
            my $args = $job -> {args};
            my $poe_slices = \@_;
            shift @{ $self -> {objects} -> {functions} };

            if ( $self -> {objects} -> {forking} ) {
                # spawn off the job
                $heap -> {child} -> {$session->ID} = POE::Wheel::Run -> new(
                    Program => sub { _dispatch(
                        { code => $code,
                          args => $args,
                          dispatcher => \$self,
                          poe => $poe_slices, } ) },
                    StdoutEvent => 'child_stdout',
                    StderrEvent => 'child_stderr',
                    CloseEvent => 'child_close', );
            } else {
                _dispatch(
                    { code => $code,
                      args => $args,
                      dispatcher => \$self,
                      poe => $poe_slices, } );
            }
        }

        # call the next dispatcher
        $_[KERNEL] -> delay_set( 'dispatcher', $self -> {objects} -> {delay} );
    }

    #warn "disp end (".$session->ID.")\n";
}

# start, when $poe_kernel -> boot()
# called

sub _start {
    $poe_kernel -> sig( HUP => 'event_sighup' );

    _dispatcher( @_ );
}

# stop, called when the kernel exiits

sub _stop {
}

# child output

sub _child_stdout {
    my $stdout = $_[ARG0];
    print "$stdout\n";
}

sub _child_stderr {
    my $stderr = $_[ARG0];
    print STDERR "$stderr\n";
}

# child close

sub _child_close {
    my $heap = $_[HEAP];
    my $session = $_[SESSION];
    delete $heap -> {child} -> {$session->ID};
}

# handle a HUP signal

sub _event_sighup {
    my $kernel = $_[KERNEL];
    my $heap = $_[HEAP];
    my $session = $_[SESSION];
    warn "Dispatcher recieved HUP\n";
    $kernel -> sig_handled();
    $KILL = 'HUP';
    $kernel -> signal( $session => 'IDLE' );
}

1;

=back
