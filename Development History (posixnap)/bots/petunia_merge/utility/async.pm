#
# Basically the run_modules sub replaces the linear modules dispatcher
# from control.pm to run modules in separate POE tasks
#
# Since a lot of stuff isn't working yet within a separate POE task
# (NVStorage, join/part), the dispatcher only grabs modules with a local
# variable $async set.
#

package utility::async;

use warnings;
use strict qw{ vars subs };

use Carp;

use utility;
use utility::communication;

use POE qw( Wheel::Run Filter::Reference );
use POE::Component::IRC;
use POE::Kernel;

use DBI;

# AS: I'm not sure how to pass this as args for the new POE tasks.
# The POE docs use global vars too in this case, so i think it's ok. 
our @modulestack;

# this sub is called from control.pm. it passes us our mode and the args we're supposed to send
# to the children.
sub run_modules {
	my ($mode, $args) = (@_);
	my @moduleargs = ($mode, $args);

	# so we take all the balls we have, and throw them up in the air. they 
	# land in start_modules -- via @modulestack, which is global.
	push @modulestack, [ $_, \@moduleargs ]
		for (grep defined ${"$utility::modules{$_}::async"} , keys %utility::modules);

	POE::Session->create ( 
		inline_states => { 
			_start => \&start_modules,
			next_module   => \&start_modules,
			module_result => \&handle_module_result,
			module_done   => \&handle_module_done,
			module_debug  => \&handle_module_debug,
		}
	);
}

sub start_modules {
	my $heap = $_[HEAP];

	# this is our throttle. I'm not convinced we need it.
	# while ( keys( %{ $heap->{module} } ) < 3 ) {

	while ( @modulestack ) {
		my ($next_module, $args) = @{ pop @modulestack };

		# we take our module, and our args, and make a sub for POE::Wheel::Run
		# to execute. In effect, we take the code from the module, stuff it into
		# a sub, and run it with the args we normally would have given it, had
		# it been executed by utility.
		my $module = POE::Wheel::Run -> new ( 
			# note $args was accidentally deref'd here previously.
			Program => sub { do_module($next_module, $args) }, 
			StdoutFilter => POE::Filter::Reference->new(),
			StdoutEvent  => "module_result",
			StderrEvent  => "module_debug",
			CloseEvent   => "module_done",
		);

		# i'm not sure what's going on here.
		$heap->{module}->{ $module->ID } = $module;
	}
}

# AS: POE currently runs this sub in a forked child process, so we 
# need to be careful with using previously initialized resources 
# (irc, classic dbi, etc.)

# what andreas is saying here is that modules which are asynchronous
# *must* be self contained. they must pull their own db connections,
# instantiate their own modules, et cetera.

sub do_module {
	# note we have already checked, these are all async modules.
	my ($module, $mode, $args) = (@_);
	my $filter = POE::Filter::Reference->new();

	# Without the evals globbing seems to take place
	# at parent compile time. Maybe i should rtfm here
	
	# with this limitation, asynchronous modules can only issue "spew" commands.
	# no notices.
	eval 'undef &utility::spew';
	eval '*utility::spew = \&async_spew';
	
	my %modules = %utility::modules;
	
	if (defined *{"$modules{$module}\::$mode"}) {
		my $sub_ref = \&{"$modules{$module}\::$mode"};
		$sub_ref -> ( @{ $args }  );
	}
	return;
}

sub override_comms {
	# sorry for this particular ugliness
	foreach my $method ( @utility::modules_overridden } ) {
		if ( 
			defined \&{"utility::$method"} and 
			not defined *{__PACKAGE__."::$method"} and
			defined *{__PACKAGE__."::async_$method"}
		) {
			debug( "overriding $method" );
			push @overridden_methods, $method;
			eval 'undef &utility::'.$method;
			eval '*utility::'.$method.' = \&async_'.$method;
			debug( $@ ) if $@;
		}
	}
}

sub async_spew {
	# shovel data to the kernel
	my $filter = POE::Filter::Reference->new();
	my %result = (	spew => [@_] );
        my $output = $filter->put( [ \%result ] );
        print @$output;
}

sub async_debug {
	# shovel data to the kernel
	my $filter = POE::Filter::Reference->new();
	my %result = (	debug => [@_] );
        my $output = $filter->put( [ \%result ] );
        print @$output;
}

# we have to handle the methods that our child is issuing.
sub handle_module_result {
	my $result = $_[ARG0];
	if ($result -> {spew}) {
		utility::communication::spew( @{$result -> {spew}} );
	}
	elsif ($result -> {debug}) {
		utility::communication::spew( @{$result -> {spew}} );
	}
	elsif ($result -> {'eval'}) { # nasty, reserved word.
		utility::communication::spew( @{$result -> {spew}} );
	}
}

sub handle_module_done {
	my ( $kernel, $heap, $module_id ) = @_[ KERNEL, HEAP, ARG0 ];
	delete $heap->{module}->{$module_id};
#	print STDERR "DONE: " . Dumper $module_id;
	$kernel->yield("next_module");
}

sub handle_module_debug {
	my $result = $_[ARG0];
	use Data::Dumper;
        print STDERR $result;
}

1;
