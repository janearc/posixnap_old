package Neopets::Pet;

use strict;
use warnings;
use Neopets::Agent;
use Neopets::Pet::Simple;
use Neopets::Debug;

our $DEBUG;

=head1 NAME

Neopets::Pet - Pet manipulation tools

=head1 SYNOPSIS

  # create a pet object and use it

  use Neopets::Agent;
  use Neopets::Pet;

  my $agent = Neopets::Agent -> new();
  my $pet = Neopets::Pet -> new(
    { agent => \$agent } );

=head1 ABSTRACT

This module provides functionality for
pet manipulation.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use constant LOOKUP_URL => 'http://www.neopets.com/randomfriend.phtml';

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $object = Neopets::Pet->new;

This constructor takes hash arguments and
returns a pet object.  Optional arguments
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

=item $pet -> current_pet();

This method selects and/or
retuns the active pet.

=cut

sub current_pet {
  my $self = shift;
  my $agent = ${ $self -> {objects} -> {agent} };
  if ( my $pet = shift ) {
    $agent -> get( { url => "http://www.neopets.com/process_changepet.phtml",
                     referer => "http://www.neopets.com/quickref.phtml",
                     params => { new_active_pet => $pet },
                 } );
  }

  my $response = $agent -> get( { url =>  "http://www.neopets.com/quickref.phtml" } );
  my ( $pet ) = $response =~ m!<a href='/quickref.phtml'>([^<]+)</a>!;

  return $self -> lookup_pet( $pet );
}

=item $pet -> lookup_pet();

This method takes a pet name and
returns the pet's information in
a Neopets::Pet::Simple object.

=cut

sub lookup_pet {
  my $self = shift;
  my $name = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $response = $agent -> post(
    { url =>  "http://www.neopets.com/search.phtml",
      params => { selected_type => 'pet',
                  string => $name },
    } );

  if ( ( $response =~ /The owner of this Neopet has had their account frozen/ )
    or ( $response =~ /nothing with this name exists/ ) )
    { debug( "Pet $name does not exist or has been frozen" ) and return Neopets::Pet::Simple -> new() }

  my @info;
  if ( $response =~ m/\(You!\)<br>/ ) {
    @info = $response
      =~ m!<b>Age</b> : <b>(\d+)</b>.*?<b>Level</b> : ([^<]+)<br><b>Owner</b> : ([^<]+).*?<b>Gender</b> : <font color=.*?<b>([^<]+)</b>.*?<b>Height</b> : ([^<]+).*?<b>Weight</b> : ([^<]+).*?<b>Hit Points</b>.*?<b>([^<]+)</b>.*?<b>Strength</b> : ([^<]+).*?<b>Defence</b> : ([^<]+).*?<b>Movement</b> : ([^<]+).*?<b>Intelligence</b> : ([^<]+)<br>!;
  } else {
    @info = $response
      =~ m!<b>Age</b> : <b>(\d+)</b>.*?<b>Level</b> : ([^<]+)<br><b>Owner</b>.*?user=([^']+)'.*?<b>Gender</b> : <font color=.*?<b>([^<]+)</b>.*?<b>Height</b> : ([^<]+).*?<b>Weight</b> : ([^<]+).*?<b>Hit Points</b>.*?<b>([^<]+)</b>.*?<b>Strength</b> : ([^<]+).*?<b>Defence</b> : ([^<]+).*?<b>Movement</b> : ([^<]+).*?<b>Intelligence</b> : ([^<]+)<br>!;
  }

  my ( $type, $species ) = $response
    =~ m!<b>$name the <font .*?>([^<]+)</font>([^<]+)</b>!;
  $species = "$type$species";

  my $pet = Neopets::Pet::Simple -> new(
    {
      name => $name,
      species => $species,
      age => shift @info,
      level => shift @info,
      owner => shift @info,
      gender => shift @info,
      height => shift @info,
      weight => shift @info,
      hp => shift @info,
      strength => shift @info,
      defence => shift @info,
      movement => shift @info,
      intelligence => shift @info,
    } );

  return $pet;
}

=item $pet -> lookup_user_pets()

This method takes a user name and
returns the pets belonging to the
given user.

=cut

sub lookup_user_pets {
  my $self = shift;
  my $name = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  my $request = $agent -> post(
    { url =>  LOOKUP_URL,
      params => { user => $name },
    } );

  my @pet_names = $request =~ m/<a href='search\.phtml\?selected_type=pet&string=([^']+)'>/g;

  my @pet_list;
  foreach ( @pet_names ) {
    my $pet = $self -> lookup_pet( $_ );
    push @pet_list, $pet;
  }

  return \@pet_list;
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
