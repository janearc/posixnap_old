#!/usr/bin/perl -w

$|++;

# begin and end times (hours)
use constant _BEGIN => 9;
#use constant _BEGIN => 0;
use constant _END   => 20;
#use constant _END   => 24;

use strict;
use warnings;
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }
#sub POE::Kernel::TRACE_DEFAULT  () { 1 }
use POE::Wheel::Dispatcher;
use Getopt::Long qw/:config bundling/;
use utility;

sub help {
    print <<EOF;

This is a dynamic script dispatcher using POE. Each
script myst have a 'run' sub.  This sub is run once
on launch and is passed a POE::Wheel::Dispatcher ref
in \$_.  'run' can then use this dispatcher to call
itself and other functions at a given interval (see
pod POE::Wheel::Dispatcher) or to call itself in a
loop.  This script will exit when the job queue is
empty.

When this script is sent a HUP signal, it
removes all jobs from the queue (after the
currently running job is completed) and re-reads
the components/ directody,Any new scripts are added
into the queue.  Scriptsremoved from the directory
will be removed from thequeue.  Unaltered scripts
will not be effected and will run at the next
scheduled time.

components/ must be in the directory from which this
script is run from.  Additionally, utility.pm must be
either in the current directory or in the perl search
path (see PERL5LIB).

EOF

}


use constant HOURS => 2;

our $heap;
our $dispatcher;

# deal with options
my ( $DEBUG, $COOKIES, $HELP );

GetOptions(
  'd'   => \$DEBUG,
  'c=s' => \$COOKIES,
  'h'   => \$HELP,
);
if ( $HELP ) {
    help();
} else {
    # XXX: np specific code here
    $heap -> {neo} -> {cookies} = $COOKIES;
    $heap -> {neo} -> {debug} = $DEBUG;

    boot();
}

exit;

# create and boot the dispatcher
sub boot {
    no strict qw/refs/;

    #my $dispatcher = POE::Wheel::Dispatcher -> new();
    $dispatcher = POE::Wheel::Dispatcher -> new();
    $utility::config{debug} = $DEBUG;

    _read_components ( 'components' );
    _load_dispatcher ( $dispatcher );

    while ( $dispatcher -> boot() ) {
        exit unless $POE::Wheel::Dispatcher::KILL eq 'HUP';
        _reload_components( $dispatcher );
    }

}

# begin utility functions

sub _read_components {
    $utility::config{moddir} = shift;
    utility::unload_old_modules();
    utility::load_default_modules();
}

sub _reload_components {
    my $d = shift;
    utility::unload_old_modules();
    _unload_dispatcher ( $d );
    utility::load_default_modules();
    _load_dispatcher ( $d );
}

sub _load_dispatcher {
    my $d = shift;
    # XXX: empty jobs from removed components
    # XXX
    $d -> delay( \&{ $utility::modules{$_}->{code}.'::run' }, _seconds(0) )
            for keys %utility::modules;
}

# remove all functions from the dispatcher
# cheap hack

sub _unload_dispatcher {
    my $d = shift;
    $d -> {objects} -> {functions} = [ ];
}

# return true if it is run time ( $begin to $end )
sub _runtime {
    my @time = localtime time();
    return ((_BEGIN <= $time[HOURS])
        and ($time[HOURS] < _END));
}

# calculate the next runtime
# XXX: this really doesn't work so well, rethink
sub _calc_runtime {
    my $delay = shift;
    my @time = localtime time();

    my $days = int( $delay / 3600 / 24 );
    my $hours_to_wait = _hours(( 24 - abs( _BEGIN - $time[2] ) )
            + ( $days * 24 ));
    return $hours_to_wait;
}

# time functions

# return a value in seconds based on an hour.
sub _hours ($) {
    return $_[0] * 3600;
}

# return a value in seconds based on a minute.
sub _minutes ($) {
    return $_[0] * 60;
}

# return a value in seconds based on a second.
# this exists solely for readability
sub _seconds ($) {
    shift;
}

# create a time stamp
sub _stamp {
    my @time = localtime( time() );
    "[$time[2]:$time[1]:$time[0]]";
}

# get rid of stupid message
$heap ? 1 : 0;

1;
