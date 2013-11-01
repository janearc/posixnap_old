package PuzzleSolver::Diffusion::World;

use constant DEFAULT_COIN_COUNT => 1000000;

use strict;
use warnings;
use PuzzleSolver::Diffusion::City qw/:checks/;
use PuzzleSolver::Diffusion::Coin qw/:checks/;
use PuzzleSolver::Diffusion::Country qw/:checks/;
use PuzzleSolver::Diffusion::Motif qw/:checks/;

use vars qw/@ISA $VERSION @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_world/;
%EXPORT_TAGS = (
    'checks' => \@EXPORT_OK
);

=head1 NAME

PuzzleSolver::Diffusion::World - A Country container

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Diffusion::World;

 my $world = PuzzleSolver::Diffusion::World -> new();

 $world -> country(
    country => $country,
    x1 => $x1,
    y1 => $y1,
    x2 => $x2,
    y2 => $y2 );

=head1 ABSTRACT

This module is designed as a container for Country objects.  It essentially represents a two dimensional grid on which City objects lie, each grouped into Countries.  It contains methods for adding Country objects and filling them with City, Coin, and Motif objects, and then retrieving them later.

=head1 METHODS

The following methods are provided:

=over 4

=item $world = PuzzleSolver::Diffusion::World -E<gt> new( %args );

This method creates and returns a World object.  Thius method takes several optional arguments in hash form.  Args are as follows:

  KEY           DEFAULT
  --------      --------
  name          undef

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $name = $args{name};

    return bless {
        objects => {
            name => $name,
            motifs => { },
            space => { },
            countries => { },
            serial => rand 10000,
        },
    }, $this;
}

=item $world -E<gt> add_country( %args );

This method adds a country to the world.  In adding a country, it adds cities and fills the cities with coins of the given motifs.  The required args are:

  KEY           VALUE
  --------      --------
  country       Country object
  country_name  scalar
  motif         Motif object
  motif_name    scalar
  x1            point
  x2            " "
  y1            " "
  y2            " "

C<country> and C<country_name> are mutually exclusive arguments.  One is used to specify a Country object to be used.  The other assumes no country object has been created and will explicitely create one.  Given both, C<country_name> will be ignored.

C<motif> and C<motif_name> are similar in function to C<country> and C<country_name>.  They are mutually exclusive.  Given both, C<motif_name> will be ignored.

The x,y coordinates specify the location of this country within the world.  The world is essentially a two dimensional array.  Touching countries form connections between cities where coins will be passed.  These coordinates myst make sense, each must be an unsigned integer and x2 and y2 must be greater than x1 and y1 respectively.

There is also an optional value:

  KEY           DEFAULT
  --------      --------
  coin_count    1000000

The coin count specifies the number of coins to be created within the cities within the generated country.

=cut

sub add_country {
    my $self = shift;
    my %args = @_;

    my $country = $args{country};
    my $country_name = $args{country_name};
    my $motif = $args{motif};
    my $motif_name = $args{motif_name};
    my $x1 = $args{x1};
    my $y1 = $args{y1};
    my $x2 = $args{x2};
    my $y2 = $args{y2};
    my $coin_count = $args{coin_count} || DEFAULT_COIN_COUNT();

    unless ( $country ) {
        die "World: add_country(): expects country or country_name argument\n"
            unless $country_name;
        $country = PuzzleSolver::Diffusion::Country -> new(
            name => $country_name );
    }

    unless ( $motif_name ) {
        die "World: add_country(): expects motif or motif_name argument\n"
            unless $motif;
        _test_motif( $motif );
        $motif_name = $motif -> name();
        die "World: add_country(): the given motif must have a name\n"
            unless $motif_name;
    }

    _test_country( $country );
    $country_name = $country -> name();

    die "World: add_country(): bad coordinates\n"
        unless _test_uint($x1) and _test_uint($x2)
            and _test_uint($y1) and _test_uint($y2)
            and ( $x1 <= $x2 ) and ( $y1 <= $y2 );

    die "World: add_country(): invalid coin_count\n"
        unless _test_uint($coin_count) and $coin_count > 0;

    $self -> {objects} -> {motifs} -> {$motif_name} = 1;
    $self -> {objects} -> {countries} -> {$country_name} = 1;

    my $space = $self -> {objects} -> {space};

    foreach  my $x ( $x1 .. $x2 ) {
        foreach my $y ( $y1 .. $y2 ) {
            if ( $space -> {$x} -> {$y} ) {
                die "There is an invalidity in country space (overlap?)\n";
            } else {
                my $c = {};
                $c -> {$motif_name} = $coin_count;
                $space -> {$x} -> {$y} = PuzzleSolver::Diffusion::City -> new(
                    coin_hash => $c, country => $country );
                
                if ( $space -> {$x-1} -> {$y} ) {
                    $space -> {$x} -> {$y} -> conn( $space -> {$x-1} -> {$y} );
                    $space -> {$x-1} -> {$y} -> conn( $space -> {$x} -> {$y} );
                }
                if ( $space -> {$x+1} -> {$y} ) {
                    $space -> {$x} -> {$y} -> conn( $space -> {$x+1} -> {$y} );
                     $space -> {$x+1} -> {$y} -> conn( $space -> {$x} -> {$y} );
                }
                if ( $space -> {$x} -> {$y-1} ) {
                    $space -> {$x} -> {$y} -> conn( $space -> {$x} -> {$y-1} );
                     $space -> {$x} -> {$y-1} -> conn( $space -> {$x} -> {$y} );
                }
                if ( $space -> {$x} -> {$y+1} ) {
                    $space -> {$x} -> {$y} -> conn( $space -> {$x} -> {$y+1} );
                     $space -> {$x} -> {$y+1} -> conn( $space -> {$x} -> {$y} );
                }
            }
        }
    }
    1;
}

=item $city = $world -E<gt> city( $x, $y );

This method returns the city at coordinate ($x,$y).  If no city is contained in this location, this returns undef.

=cut

sub city {
    my $self = shift;
    my $x = shift;
    my $y = shift;

    return $self -> {objects} -> {space} -> {$x} -> {$y};
}

=item $bool = $world -E<gt> complete( %args );

This method tests if city or country objects are complete.  %args are as such:

  KEY           DEFAULT
  --------      --------
  city          undef
  country       undef

C<city> will test if the given city object is complete.  This means that this city has atleast one coin from each motif.  Generally, once a city is complete it stays complete, however under certain circumstances, a complete city can become incomplete.  C<city> and C<country> are murually exclusive.

C<country> will test if the given country is complete.  This means that every city belonging to the country is complete.  C<city> and C<country> are murually exclusive.

=cut

sub complete {
    my $self = shift;
    my %args = @_;

    die "World: complete(): must take a hash argument with a city `or' country key\n"
        unless $args{city} xor $args{country};

    if ( $args{city} ) {
        _test_city( $args{city} );
        foreach my $motif ( keys %{ $self -> {objects} -> {motifs} } ) {
            return unless $args{city} -> coins() -> {$motif}
        }
        return 1;
    } elsif ( $args{country} ) {
        foreach  my $x ( keys %{ $self -> {objects} -> {space} } ) {
            foreach my $y ( keys %{ $self -> {objects} -> {space} -> {$x} } ) {
                my $city = $self -> {objects} -> {space} -> {$x} -> {$y};
                if ( $city -> country() -> name() eq $args{country} ) {
                    return unless $self -> complete( city => $city )
                }
            }
        }
        return 1;
    } 
}
        
=item @motifs = @{ $world -E<gt> motifs() };

This method returns the names of motifs created while using C<add_country()>.  This should represent all motifs at work within this world.

=cut

sub motifs {
    my $self = shift;
    my @ar = keys %{ $self -> {objects} -> {motifs} };
    return \@ar;
}

=item @countries = @{ $world -E<gt> countries() };

This method returns the names of countries created while using C<add_country()>.  This should represent all countries within the world.
=cut

sub countries {
    my $self = shift;
    my @c = keys %{ $self -> {objects} -> {countries} };
    return \@c;
}

=item $space = $world -E<gt> space();

This method returns the city space contained within this object.  The city space is defined as a hashref of hashrefs containing cities added by C<add_country()>.  The best way to use this space is with:

  $city = $space -> {$x} -> {$y};

where C<$x> and C<$y> are coardinates within the city space.  Coordinates not containing a city are simply C<undef>.

It is probably a better idea to use C<city()> if you want cities at coordinates.  Changes to the structure returned by this method can alter the function of this module.  Use this with caution.  It is designed only for use by the Agent.

=cut

sub space {
    my $self = shift;
    return $self -> {objects} -> {space};
}

=item $world -E<gt> set_space( $space );

This method sets the internal space representation.  Do not use this unless you know what you are doing.  It is designed only for use by the Agent.

=cut

sub set_space {
    my $self = shift;
    my $space = shift || die "World: set_space(): requires a space object\n";
    $self -> {objects} -> {space} = $space;
}

=item $bool = $world -E<gt> is_equal( $other_world );

This method returns true if C<$world> and C<$other_world> are equal, C<undef> otherwise.  This is done by comparing a random serial number contained within every World object, generated once upon creation.

=cut

sub is_equal {
    my $self = shift;
    my $w = shift;
    _test_world( $w );
    return $self -> {objects} -> {serial}
        == $w -> {objects} -> {serial};
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_word( $world );

This method performs a sanity check on the value C<$world>.  It returns true if C<$world> is a World or compatable object.  On a negative, this method C<die()>s.

=cut

sub _test_world {
    my $w = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects World object\n";
    die "$e" unless ref $w
        and $w -> can( 'add_country' )
        and $w -> can( 'city' )
        and $w -> can( 'space' )
        and $w -> can( 'is_equal' );
    return $w;
}

=item $retval = _test_uint( $int );

This method performs a sanity check on the value C<$int>.  It returns true if C<$int> is an unsigned integer.  This is mostly used internally by this module.

=cut

#sub _test_uint {
#    my $i = shift;
    #my ($x, $y, $z, $sub) = caller(1);
    #my $e = "Die: $sub(): expects unsigned integer\n";
    #die "$e" unless $i;
#    return unless defined $i;
#    return if ref $i;
#    return int($i) eq $i
#        and $i >= 0;
#}

=back

=cut

1;
