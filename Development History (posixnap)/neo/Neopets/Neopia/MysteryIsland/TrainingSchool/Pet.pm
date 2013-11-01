package Neopets::Neopia::MysteryIsland::TrainingSchool::Pet;

use warnings;
use strict;
use Data::Dumper;

# Pet.pm
# mostly private class for TrainingSchool.pm (pun intended)

# new( "petname", { level => 10, [ ... ] } )
sub new {
	my $self = shift;
	my $return_self = ref( $self ) || $self;

	my ($agent, $name, $stats) = (@_);

	if (not $agent) {
		die "$0: new: no agent passed!\n";
	}
	
	if (not length $name) {
		die "$0: new: no name passed!\n";
	}

	return bless { 
		name => $name,
		stats => $stats || {},
		objects => { AGENT => $agent } 
	}, $return_self;
}

# status()
# return a $pet's level, strength, defense, movement, and hitpoints in a hashref
sub status {
	my $self = shift; # this is a $pet
	# we do this for ease of typing
	my $base_url = 'http://www.neopets.com/island/training.phtml';
	my $name = $self -> {name};
	my $status_url = $base_url."?type=status";

	my $page = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => $status_url,
		  referer => $base_url,
          no_cache => 1,
	} );

	die "$0: pets: failure getting $status_url. sorry.\n" unless $page;

	# this could be done a little more concisely, on one line. but it would 
	# be an ugly regex. This really is clearler.
	my $this_pet = (split /<td bgcolor='#dddd77' width=450 colspan=2><b>$name/, $page)[1];
	my ($level) = $this_pet =~ /Level\s+(\d+)/;
	my ($strength) = $this_pet =~ /Str\s+:\s+<b>(\d+)/;
	my ($defense) = $this_pet =~ /Def\s+:\s+<b>(\d+)/;
	my ($movement) = $this_pet =~ /Mov\s+:\s+<b>(\d+)/;
	my ($hp_min, $hp_max) = $this_pet =~ /Hp\s+:\s+<b>(\d+)\s+\/\s+(\d+)/;

	my $stats = {
		level => $level,
		strength => $strength,
		defense => $defense,
		movement => $movement,
		hp_max => $hp_max,
		hp_min => $hp_min,
	};
	
	return $stats;
}

# cs_required()
# return the codestone required to train a $pet, or undef if it does not
# require one (i.e., has not been signed up or is currently training)
# XXX: ugh, this is going to break for levels > 20
sub cs_required {
	my $self = shift; # $pet

	my $base_url = 'http://www.neopets.com/island/training.phtml';
	my $name = $self -> {name};
	my $status_url = $base_url."?type=status";

	my $page = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => $status_url,
		  referer => $base_url,
	} );

	die "$0: pets: failure getting $status_url. sorry.\n" unless $page;

	# XXX: if you name your pet "codestone", you deserve to get this code broken
	my @petstatus = split /bgcolor='#dddd77'/, $page;
	my ($this_pet) = grep { /colspan=2><b>$name/ } @petstatus;
	my (@cs_required) = $this_pet =~ /<b>([-A-Za-z]+\s+Codestone)<\/b>/gs;
	return @cs_required ? \@cs_required : undef;
}

# is_completed()
# return true if a pet is completed training, false if not.
sub is_completed {
	my $self = shift; # $pet

	my $base_url = 'http://www.neopets.com/island/training.phtml';
	my $name = $self -> {name};
	my $status_url = $base_url."?type=status";
	
	my $page = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => $status_url,
		  referer => $base_url,
	} );

	die "$0: pets: failure getting $status_url. sorry.\n" unless $page;
    
	# XXX: if you name your pet "codestone", you deserve to get this code broken
	my ($this_pet) = grep { /$name/ and /Lvl/ } split /bgcolor='#dddd77'/, $page;
	if ($this_pet =~ /Course Finished!/i) {
		return 1;
	}
	else {
		return 0;
	}
}

# is_training()
# return seconds remaining if a pet is actively training, false if not.
sub is_training {
	my $self = shift; # $pet

	my $base_url = 'http://www.neopets.com/island/training.phtml';
	my $name = $self -> {name};
	my $status_url = $base_url."?type=status";
	
	my $page = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => $status_url,
		  referer => $base_url,
          no_cache => 1,
	} );

	die "$0: pets: failure getting $status_url. sorry.\n" unless $page;

	# XXX: if you name your pet "codestone", you deserve to get this code broken
	my ($this_pet) = grep { /$name/ and /Lvl/ } split /bgcolor='#dddd77'/, $page;
	
	my ($hrs, $mins, $secs) = $this_pet =~ /(\d+)\s+hrs,\s+(\d+)\s+minutes,\s+(\d+)\s+seconds/;
	if ($hrs or $mins or $secs) {
		my $secs_remaining = ($hrs * (60 * 60)) + ($mins * 60) + $secs;
		
		return $secs_remaining;
	}
	else {
		return 0;
	}
}

# it_to_localtime( $secs_rem, "SCALAR" )
# returns in plain english (or epoch second) when a pet will finish training.
# sure, fluff, but convenient.
sub it_to_localtime {
	my ($self, $secs_rem, $type) = (@_);
	return $type ? scalar localtime( time() + $secs_rem ) : time() + $secs_rem;
}

# complete_course()
# complete course if pet is done studying.
sub complete_course {
	# <form action='process_training.phtml' method='post'><input type='hidden' name='type' value='complete'><input type='hidden' name='pet_name' value='thesecondfluffy'><input type='submit' value='Complete Course!'></form>
	my $self = shift;
	my $get = 'http://www.neopets.com/island/process_training.phtml?type=complete&pet_name=';
	my $response = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => $get.$self -> {name},
		  referer => 'http://www.neopets.com/island/training.phtml?type=status',
	} );

	return 1 unless $response;
	return undef;
}

1;

=head1 NAME

	Neopets::Neopia::MysteryIsland::TrainingSchool::Pet.pm

=head1 SYNOPSIS

	Mostly private subclass for TrainingSchool.

=head1 ABSTRACT

	my $pet = Neopets::Neopia::MysteryIsland::TrainingSchool::Pet -> new( 
		"petname", { 
			Level => 10, 
			[ ... ] 
		} 
	);

	my $status = $pet -> status();

	my $stones = $pet -> cs_required();

	if (my $time = $pet -> is_training()) {
		# ...
	}

	my $english_time_rem = $pet -> it_to_localtime( 
		$pet -> is_training(), "SCALAR" 
	);

=head1 METHODS

	new()

	the object constructor takes two arguments. the first argument is the pet's
	name, in a plain text scalar. the second argument is a hashref containing
	the pet's statistics. since this class is not intended to be used except by
	its parent, the specifics of this hashref are left as an excercise to the
	reader. there are comments in the source.

	status()

	status returns a hashref containing the pet's status in the school, 
	including hitpoints, level, etc. the output from this method is suitable for
	feeding to the object constructor.
	
	cs_required()

	cs_required returns an arrayreference containing scalars containing the names
	of the codestones required to pay for a course the pet is currently taking.
	the reason an arrayref is returned is on later levels, more than one is
	required.

	is_training()

	is_training returns the time, in seconds, until the pet will finish the 
	training it is currently enrolled in. this is sufficient for treating the 
	result as a boolean.

	it_to_localtime()

	it_to_localtime returns either the epoch second when training will 
	complete, or, when passed a true value for its second argument, the date in
	plain text when the pet will finish.

=head1 SUB CLASSES

	none.

=head1 COPYRIGHT

	the Neopets:: modules are the combined works of Matt Harrington and
	Alex Avriette. Please see the accompanying CREDITS file for more 
	information.

=head1 LICENSE
	
	please see the accompanying LICENSE file for more information.
