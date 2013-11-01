package Neopets::Neopia::MysteryIsland::TrainingSchool;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

#
# TrainingSchool.pm
# provide methods for sending Neopets Pets to training at the
# Neo-Fu academy.
#

our $BASE_URL = 'http://www.neopets.com/island/training.phtml';

# constructor takes agent
# my $school = Neopets::Neopia::MysteryIsland::TrainingSchool -> new();
sub new {
  my $inner_self = shift;
  my $outer_self = ref( $inner_self ) || $inner_self;
  my ( $args ) = @_;

  my $agent = $args -> {agent};
  $DEBUG = $args -> {debug};

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }

  return bless {
    objects => {
      AGENT => $agent,
    },
  }, $outer_self;
}

# pets()
# return $pet objects so we can issue $pet -> train( { Discipline => Strength } )
sub pets {
	use Neopets::Neopia::MysteryIsland::TrainingSchool::Pet;
	my $self = shift; # this is a $school
	my $status_url = $BASE_URL."?type=status";
	my $response = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => $status_url,
		  referer => $BASE_URL,
          no_cache => 1,
	} );

    my $page;
	unless ( $page = $response ) {
		die "$0: pets: failure getting $status_url. sorry.\n";
	}

	my (%pets, @out);
	$pets{$1} = { level => $2 } while $page =~ /<td bgcolor='#dddd77' width=450 colspan=2><b>([^(]+?)\s+\(Level\s+(\d+)\)/g;
	foreach my $pet (keys %pets) {
		push @out, Neopets::Neopia::MysteryIsland::TrainingSchool::Pet -> new( 
			$self -> {objects} -> {AGENT},	# agent
			$pet,	# petname
			$pets{$pet}, # pet status hashref
		)
	}
	return \@out;
}

# pay_for_training( \$pet )
# takes a reference to a $pet object and pays for training.
# checks inventory first to see if the required codestone is
# present in the inventory
sub pay_for_training {
	my $self = shift; # $school
	my $pet = shift;

	$pet = ${ $pet };

	my $response = ${ $self -> {objects} -> {AGENT} } -> get(
		{ #url => "http://www.neopets.com/island/process_training.phtml?type=pay&pet_name=".$pet -> {name},
          url => "http://www.neopets.com/island/process_training.phtml",
		  referer => "http://www.neopets.com/island/training.phtml?type=status",
          no_cache => 1,
          params =>
            {  type => 'pay',
               pet_name => $pet -> {name},
            },
        }
	);

	return 1; # XXX: there is no debug info or confirmation. that should be added.
}

# train( \$pet, { Discipline => Strength } )
# train a given $pet reference in requested discipline
sub train {
	my ($self, $pet, $href) = (@_);

	$pet = ${ $pet };
	
	if ($pet -> is_training()) {
		warn "$0: train: ".$pet -> {name}." is training until ".$pet -> it_to_localtime( $pet -> is_training() )."\n";
		return undef;
	}

	if (not $href -> {Discipline}) {
		fatal( "please pass a hash ref argument" );
		return undef;
	}

	$href -> {Discipline} = ucfirst $href -> {Discipline};

	# XXX: this is such a dirty hack. shaaaame.
	my $params = "";
	$params .= "&pet_name=".$pet -> {name};
	$params .= "&course_type=".$href -> {Discipline};
	$params .= "&type=start";

	my $response = ${ $self -> {objects} -> {AGENT} } -> get(
		{ url => "http://www.neopets.com/island/process_training.phtml?".$params,
		  referer => "http://www.neopets.com/island/training.phtml?type=courses",
          no_cache => 1,
	} );

	die "$0: train: failed sending $params\n" unless $response;

	#die $response;
	return 1;
}

1;
=head1 NAME

	Neopets::Neopia::MysteryIsland::TrainingSchool

=head1 SYNOPSIS

	A small module to abstract some of the functions available at the Neo-Fu
	academy available on Neopets' MysteryIsland.

=head1 ABSTRACT

	my $school = Neopets::Neopia::MysteryIsland::TrainingSchool -> new( \$agent );
	my $pets = $school -> pets();
	my $result = $school -> pay_for_training( \$pet );
	my $result = $school -> train( \$pet, { Discipline => 'Strength' } );

=head1 METHODS

	new()

	new requires a Neopets::Agent object, but will attempt to create one if
	you don't pass it one.

	pets()

	returns an arrayref containing 
	Neopets::Neopia::MysteryIsland::TrainingSchool::Pet objects. For example:

	my $pets = $school -> pets();
	my @cs_required = @{ $pets -> [0] -> cs_required() };

	pay_for_training()

	pays for the training for that particular pet. requires a reference to 
	a $pet object. ensuring that you actually have the requisite codestone(s)
	is up to you.

	train()

	sends the provided $pet reference to training, with the discipline to
	study specified by a hash reference.

=head1 SUB CLASSES

	Neopets::Neopia::MysteryIsland::TrainingSchool::Pet

=head1 COPYRIGHT

	The Neopets:: modules are the combined works of Matt Harrington and
	Alex Avriette, (c) 2002. Please see the accompanying CREDITS file
	for more information.

=head1 LICENSE

	Please see the enclosed LICENSE file for more information.
