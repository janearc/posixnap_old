package PuzzleSolver::Diffusion::Country;

use strict;
use warnings;
use PuzzleSolver::Diffusion::City qw/:checks/;
use Exporter;

use vars qw/@ISA $VERSION @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_country _test_countries/;
%EXPORT_TAGS = (
    'checks' => \@EXPORT_OK
);

=head1 NAME

PuzzleSolver::Diffusion::Country - A Country object

=head1 SYNOPSIS

 use PuzzleSolver::Diffusion::Country;

 my $country = PuzzleSolver::Diffusion::Country -> new(
    cities => \@cities, name => $name );
 
 $name = $country -> name();

 @cities = @{ $country -> cities() };

=head1 ABSTRACT

This module represents a Country in the motif diffusion simulation.  Its purpose is to hold zero or more cities of the same country.

=head1 METHODS

The following methods are provided:

=over 4

=item $country = PuzzleSolver::Diffusion::Country -E<gt> new( %args );

  KEY           DEFAULT
  --------      --------
  name          undef
  cities        [ ]

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $name = $args{name};
    my $cities = $args{cities} || [ ];

    my $self = bless {
        objects => {
            name => $name,
            serial => rand 10000,
            cities => [ ],
        },
    }, $this;

    foreach ( @{ $cities } ) {
        _test_city( $_ ) and $_ -> country( $self )
    }

    $self -> {objects} -> {cities} = $cities;

    return $self;
}

=item $name = $country -E<gt> name( $name );

This method returns the name of the country.  Optionally, this will also set the name of then country when given a scalar argument.

=cut

sub name {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {name} = shift;
    }
    return $self -> {objects} -> {name};
}

=item ${ @cities } = $country -E<gt> cities( \@cities );

This method returns an arrayref of cities within the country.  Optionally, this will also set the list of cities when passed an arrayref of cities.

=cut

sub cities {
    my $self = shift;
    if ( @_ ) {
        my $c = shift;
        $self -> {objects} -> {cities} = $c;
        _test_cities( $c );
    }
    return $self -> {objects} -> {cities};
}


=item $bool = $country -E<gt> is_equal( $other_country );

This method returns true if C<$country> is equal to C<$other_country>.  This is done by comparing a serial number generated during the creation of the Country objects.

=cut

sub is_equal {
    my $self = shift;
    my $c = shift;
    _test_country( $c );
    return $self -> {objects} -> {serial}
        == $c -> {objects} -> {serial};
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $revtal = _test_country( $country );

This method performs a sanity check on the value C<$country>.  It returns true if C<$country> is a Country or compatable object.  On a negative, this method C<die()>s.

This is also exported with the export tag C<:checks>.

=cut

sub _test_country {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects Country object\n";

    die $e unless ref $c
        and $c -> can( 'name' )
        and $c -> can( 'cities' )
        and $c -> can( 'is_equal' );
    $c;
}

=item $retval = _test_countries( \@coins );

This method is identical to _test_countries() but it tests an arrayref of countries instead of a single country.

This is also exported with the export tag C<:checks>.

=cut

sub _test_countries {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects arrayref of Country objects\n";

    die $e unless ref( $c ) eq 'ARRAY';
    foreach ( @{ $c } ) {
        die $e unless ref $_
            and $_ -> can( 'name' )
            and $_ -> can( 'cities' )
            and $_ -> can( 'is_equal' );
    }
    $c;
}


=cut

=back

=cut

1;
