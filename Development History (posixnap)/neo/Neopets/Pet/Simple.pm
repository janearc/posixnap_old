package Neopets::Pet::Simple;

use strict;
use warnings;

=head1 NAME

Neopets::Pet::Simple - A data sctructure for holding pet based information

=head1 SYNOPSIS

  # create a pet object and set it

  use Neopets::Pet::Simple;

  my $pet = Neopets::Pet::Simple -> new();

  $age      = $pet -> age();
  $defence  = $pet -> defence();
  $gender   = $pet -> gender();
  $height   = $pet -> height();
  $hp       = $pet -> hp();
  $intelligence = $pet -> intelligence();
  $level    = $pet -> level();
  $movement = $pet -> movement();
  $name     = $pet -> name();
  $owner    = $pet -> owner();
  $species  = $pet -> species();
  $strength = $pet -> strength();
  $weight   = $pet -> weight();

  $pet -> age( $age );
  $pet -> defence( $defence );
  $pet -> gender( $gender );
  $pet -> height( $height );
  $pet -> hp( $hp );
  $pet -> intelligence( $intelligence );
  $pet -> level( $level );
  $pet -> movement( $movement );
  $pet -> name( $name );
  $pet -> owner( $owner );
  $pet -> species( $species );
  $pet -> strength( $strength );
  $pet -> weight( $weight );

=head1 ABSTRACT

This is a simple module for storing pet related
information.

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

=item $object = Neopets::Pet::Simple;

This creates a pet object.  Optionally
it takes a hash representing the data to
be stored.

  new( {
         name => $name,
	 level => $level,
     } );

=cut

sub new {
  my $that = shift;
  my $this = ref($that) || $that;
  my ( $args ) = @_;

  my $data = {
      name => $args -> {name},
      level => $args -> {level},
      species => $args -> {species},
      owner => $args -> {owner},
      age => $args -> {age},
      defence => $args -> {defence},
      gender => $args -> {gender},
      height => $args -> {height},
      hp => $args -> {hp},
      intelligence => $args -> {intelligence},
      movement => $args -> {movement},
      strength => $args -> {strength},
      weight => $args -> {weight},
  };

  return bless $data, $this;
}

=item $pet -> age( $age );

Sets or retrieves the pet age.
$age is optional.

=cut

sub age {
  my $self = shift;
  @_ and $self -> {age} = shift;
  return $self -> {age};
}

=item $pet -> defence( $defence );

Sets or retrieves the pet defence.
$defence is optional.

=cut

sub defence {
  my $self = shift;
  @_ and $self -> {defence} = shift;
  return $self -> {defence};
}

=item $pet -> gender( $gender );

Sets or retrieves the pet gender.
$gender is optional.

=cut

sub gender {
  my $self = shift;
  @_ and $self -> {gender} = shift;
  return $self -> {gender};
}

=item $pet -> height( $height );

Sets or retrieves the pet height.
$height is optional.

=cut

sub height {
  my $self = shift;
  @_ and $self -> {height} = shift;
  return $self -> {height};
}

=item $pet -> hp( $hp );

Sets or retrieves the pet hp.
$hp is optional.

=cut

sub hp {
  my $self = shift;
  @_ and $self -> {hp} = shift;
  return $self -> {hp};
}

=item $pet -> intelligence( $intelligence );

Sets or retrieves the pet intelligence.
$intelligence is optional.

=cut

sub intelligence {
  my $self = shift;
  @_ and $self -> {intelligence} = shift;
  return $self -> {intelligence};
}

=item $pet -> level( $level );

Sets or retrieves the pet level.
$level is optional.

=cut

sub level {
  my $self = shift;
  @_ and $self -> {level} = shift;
  return $self -> {level};
}

=item $pet -> movement( $movement );

Sets or retrieves the pet movement.
$movement is optional.

=cut

sub movement {
  my $self = shift;
  @_ and $self -> {movement} = shift;
  return $self -> {movement};
}

=item $pet -> name( $name );

Sets or retrieves the pet name.
$name is optional.

=cut

sub name {
  my $self = shift;
  @_ and $self -> {name} = shift;
  return $self -> {name};
}

=item $pet -> owner( $owner );

Sets or retrieves the pet owner.
$owner is optional.

=cut

sub owner {
  my $self = shift;
  @_ and $self -> {owner} = shift;
  return $self -> {owner};
}

=item $pet -> species( $species );

Sets or retieves the pet species.
$species is optional.

=cut

sub species {
  my $self = shift;
  @_ and $self -> {species} = shift;
  return $self -> {species};
}

=item $pet -> strength( $strength );

Sets or retrieves the pet strength.
$strength is optional.

=cut

sub strength {
  my $self = shift;
  @_ and $self -> {strength} = shift;
  return $self -> {strength};
}

=item $pet -> weight( $weight );

Sets or retrieves the pet weight.
$weight is optional.

=cut

sub weight {
  my $self = shift;
  @_ and $self -> {weight} = shift;
  return $self -> {weight};
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
