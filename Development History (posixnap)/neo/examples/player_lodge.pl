#!/usr/bin/perl

#
# player_lodge.pl
# 
# automatic, event driven maintenance for neopets accounts. this code
# violates the license for the Neopets:: modules and as such cannot
# be used or distributed with the Neopets:: modules.
#
# if you must, think of it as a "player" lodge instead of a "pet"
# lodge.
#

# =============-------------------------
# strictures and debugging
use warnings;
use strict;
use Carp qw{ cluck croak carp confess };
use Data::Dumper;
# =============-------------------------

# =============-------------------------
# core modules of the script
use POE;
use POE::Kernel;
use POE::Session;
# =============-------------------------

# =============-------------------------
# the neopets:: modules which will be used
use Neopets::Agent;
use Neopets::Shops;
use Neopets::Config;
use Neopets::Item::Simple;
use Neopets::Shops::Wizard;
use Neopets::Neopia::MysteryIsland::Tombola;
use Neopets::Neopia::LostDesert::FruitMachine;
use Neopets::Neopia::LostDesert::ColtzansShrine;
use Neopets::Neopia::Faerieland::HealingSprings;
use Neopets::Neopia::MysteryIsland::TrainingSchool;
# =============-------------------------

# =============-------------------------
# read our config file
my $cfg_parser = Neopets::Config -> new( );
my $config = $cfg_parser -> read_config({ file => 'lodge.xml' });
# =============-------------------------

# =============-------------------------
# create some neopets objects
my $agent = Neopets::Agent -> new({ });
my $shop = Neopets::Shops -> new({ agent => \$agent });
my $wizard = Neopets::Shops::Wizard -> new({ agent => \$agent });
my $tombola = Neopets::Neopia::MysteryIsland::Tombola -> new({ agent => \$agent });
my $spring = Neopets::Neopia::Faerieland::HealingSprings -> new({ agent => \$agent });
my $shrine = Neopets::Neopia::LostDesert::ColtzansShrine -> new({ agent => \$agent });
my $school = Neopets::Neopia::MysteryIsland::TrainingSchool -> new({ agent => \$agent });
my $fruit_machine = Neopets::Neopia::LostDesert::FruitMachine -> new({ agent => \$agent });
# =============-------------------------

boot();
$poe_kernel -> run();
print "\$kernel has returned from the beyond. Rapture.";
exit 0;

# =============-------------------------
# utility subs
# named with _sub for convenience of identification.
# =============-------------------------

# debug
# general debugging sub also returning caller.
sub _debug ($) {

  my ($package, $line, $subroutine) = ( caller(1) )[0, 2, 3];
  my $prefix = "$0: $package: $subroutine"."[$line]: ";

	# we print to STDERR here instead of "warn" so that we avoid the 
	# blah at foo.pl line XYZ.
  print STDERR $prefix.$_[0].$/;
}

# return a value in seconds based on an hour.
sub _hours ($) {
	return $_[0] * 360;
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

# return a random number of minutes so it doesnt look like 
# we're running a script.
sub _randmin () {
	return ((int rand 10) + 2) * 60;
}

# buy an item from the wizard at less than the preferred price
sub _wizbuy_choice {
	my ($item, $preferred_price) = (@_);
	
	# execute the search.
	my @prospects = @{ $wizard -> search( {
		item => $item,
		max_price => $preferred_price,
	} ) };

	# {{{ error checking from the wizard. hopefully matt will make this go away.
	my ($result, $delay) = $prospects[0];
	if ($result eq uc 'busy') {
		_debug "wizard was busy, sleeping $delay minutes\n";
		return _minutes( $delay ) + _randmin();
	}
	elsif ($result eq uc 'none found') {
		_debug "nothing found\n";
		return _seconds( 2 );
	}
	undef $result; undef $delay;
	# }}} error checking

	PROSPECT: foreach my $prospect (@prospects) {
		# these are $item objects
		next PROSPECT if $prospect -> owner() eq $agent -> username();
		my $listing = $shop -> listing( $prospect -> owner() );
		# matt says this will change RSN.
		if ($prospect -> location( $listing -> { $prospect -> name() } ) ) {
			if ($shop -> buy( $prospect )) {
				_debug "Grabbed ".$item -> name()." at ".$item -> price()."\n";
				# this is sufficiently different from the delays that we know 
				# we bought something. this can be used to decrease the tally
				# elsewhere.
				return -1; 
			}
			else { 
				_debug $item -> name()." was sold out after listing was gotten.\n";
				return _seconds( 2 );
			}
		}
		# they were sold out before the listing.
		_debug $item -> name()." was sold out before we could get the listing.\n";
		return _seconds( 2 );
	}
}

# =============-------------------------
# procedural subs
# these subs perform a task and return the time until they should be
# executed again.
# =============-------------------------

# healing_springs
# takes no args
# returns time (in seconds) it should sleep until executed again.
sub ps_healing_springs {
	_debug $spring -> heal(),
	return _hours(.5) + _minutes(_randmin());
}

# coltzans_shrine
# takes no args
# returns time (in seconds) it should sleep until executed again.
sub ps_coltzans_shrine {
	_debug $shrine -> visit();
	return _hours(24) + _minutes(_randmin());
}

# tombola
# takes no args
# returns the time (in seconds) it should sleep until executed again.
sub ps_tombola {
	_debug $tombola -> grab();
	return _hours(24) + _minutes(_randmin());
}

# fruit_machine
# takes no args
# returns the time (in seconds) it should sleep until executed again.
sub ps_fruit_machine {
	_debug $fruit_machine -> spin();
	return _hours(24) + _minutes(_randmin());
}

# autotrain
# takes $petname and $discipline
# returns the time (in seconds) it should sleep until executed again.
sub ps_autotrain {
	my ($petname, $discipline) = (@_);
	unless ($petname) {
		# XXX: THIS IS BROKEN. THIS IS A QUICK HACK FOR TESTING PURPOSES. NORMALLY
		# WE WOULD HAVE AN ARRAY REFERENCE HERE.
		$petname = $config -> { 'player' } -> { 'train-list' } -> { 'pet' } -> { 'name' };
	}
	unless ($discipline) {
		# see disclaimer above
		$discipline = ucfirst
			$config -> { 'player' } -> { 'train-list' } -> { 'pet' } -> { 'discipline' };
	}

	my ($pet) = grep { uc $_ -> {name} eq uc $petname } @{ $school -> pets() };

	if ( not $petname or not $pet ) {
		# you may not name your pet '0'.
		_debug "please provide the name of a pet you own.";
		return undef;
	}

	if ($pet -> is_training()) {
		print $pet -> {name}." is currently training until ".
			$pet -> it_to_localtime( $pet -> is_training() ). ".\n";
		return undef;
	}
	
	if ($pet -> is_completed()) {
		$pet -> complete_course();
		return _seconds(3);
	}

	if ( my $cs = $pet -> cs_required()) {
		foreach my $stone ( @{ $cs } ) {
			# "true" until buy_direct() returns true.
			1 until ($shop -> buy_direct( $stone ));
		}
		$school -> pay_for_training( \$pet )
			and _debug $pet -> {name}." has been paid for\n";
		return _seconds(3);
	}

	if (not $discipline = ucfirst $discipline) {
		_debug "please provide a discipline\n";
		return undef;
	}
	$school -> train( \$pet, { Discipline => $discipline } );
	
	return _seconds(3);
}

# do_wiz
# takes its arguments from the config.
# returns the time (in seconds) it should sleep until executed again.
sub ps_do_wiz {
	60;
}

# =============-------------------------
# core
# these subs are responsible for the overall "working" nature of
# this program.
# =============-------------------------

sub boot {
	{
		no strict qw{ refs };
		# $alarm_id = $kernel->delay_set( $event, $seconds_hence, @etc );
		$poe_kernel -> delay_set( $_, &{ "$_" } ) for 
			grep { /^(ps_.+)/ and defined &{ "$1" } } %{ "main::" };
	}
}

