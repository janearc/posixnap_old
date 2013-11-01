package PuzzleSolver::Diffusion::City;

use strict;
use warnings;
use PuzzleSolver::Diffusion::Coin qw/:checks/;
use PuzzleSolver::Diffusion::Motif qw/:checks/;
use PuzzleSolver::Diffusion::Country qw/:checks/;
use Exporter;

use vars qw/@ISA $VERSION @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_city _test_cities/;
%EXPORT_TAGS = (
    'checks' => \@EXPORT_OK
);

=head1 NAME

PuzzleSolver::Diffusion::City - A city object

=head1 SYNOPSYS

  use strict;
  use PuzzleSolver::Diffusion::City;

  my $c = PuzzleSolver::Diffusion::City -> new(
    coins => \@coins );

  ${ @coins } = $c -> coins();
  $country = $c -> country();

=head1 ABSTRACT

This module represents a single city object.  The purpose of this object is to hold coins and maintain connections to other cities.  This information will later be manipulated by an Agent object.

=head1 METHODS

The following methods are provided:

=over 4

=item $city = PuzzleSolver::Diffusion::City -E<gt> new( %args );

This method creates and returns a city object.  This method takes optional args in hash form.  Args arre as such:

  KEY           DEFAULT
  --------      --------
  coins         [ ]
  coin_hash     { }
  connections   [ ]
  country       undef

C<coins> is an arrayref of initial coins to be held by this country.  C<coins> and C<coin_hash> are mutually exclusive.

C<coin_hash> is a hashref containing motif name keys and unsigned integer values.  This represents the number of coins of each motif.  This is much faster but not as nice as the coin object method.  C<coins> and C<coin_hash> are mutually exclusive.

C<connections> is an arrayref of city objects, connections this city has with outher cities.

C<country> is the country object this city object belongs to.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $conns = $args{connections} || [ ];
    foreach ( @{ $conns } )
        { _test_city( $_ ) }
    
    my $country = $args{country};
    if ( $country )
        { _test_country( $country ) }

    my $coins = $args{coins} || [ ];
    _test_coins( $coins );

    my $coin_hash = $args{coin_hash} || { };
    _test_uint_hash_coins( $coin_hash );

    return bless {
        objects => {
            coins => _sort_coins( $coins ),
            coin_hash => $coin_hash,
            conns => $conns,
            country => $country,
            serial => rand 10000,
        },
    }, $this;
}

=item $city -E<gt> conn( $other_city );

This method connects this city with another.  All connections are one way.

=cut

sub conn {
    my $self = shift;
    my $c = shift;
    _test_city( $c );
    push @{ $self -> {objects} -> {conns} }, $c;
    1;
}

=item @connections = @{ $city -E<gt> connections() };

This method returns all connections this city has made.  If no connections have been made, this will return an empty arrayref.

=cut

sub connections {
    my $self = shift;
    return $self -> {objects} -> {conns};
}

=item $coins = $city -E<gt> coins();

This method return the coins contained within this city.  If no coins are found, it will default to the coin object method and return an empty arrayref.

=cut

sub coins {
    my $self = shift;
    if ( keys %{ $self -> {objects} -> {coin_hash} } ) {
        return $self -> {objects} -> {coin_hash};
    } else {
        return _unsort_coins( $self -> {objects} -> {coins} );
    }
}

=item $city -E<gt> set_coins( \@coins );

This method sets the coin objects held within this city.  It will delete any hashref coins contained within.

=cut

sub set_coins {
    my $self = shift;
    my $c = shift;
    $self -> {objects} -> {coins} = _sort_coins( $c );
    $self -> {objects} -> {coin_hash} = { };
    _test_coins( $c );
}

=item $city -E<gt> set_hash_coins( \%coins );

this method sets the hash coin object held within the city.  It will delete any coin objects contained within.

=cut

sub set_hash_coins {
    my $self = shift;
    my $c = shift;
    $self -> {objects} -> {coin_hash} = $c;
    $self -> {objects} -> {coins} = [ ];
    _test_uint_hash_coins( $c );
}

=item $country = $city -E<gt> country();

This method returns the country this city is associated with.  This value is set when the city is created or when it is added to a country.

=cut

sub country {
    my $self = shift;
    return $self -> {objects} -> {country};
}

=item $bool = $city -E<gt> is_equal( $other_city );

This method returns true if C<$city> is equal to C<$other_city>.  This is done based on a random serial number generated during the creation of the City objects.

=cut

sub is_equal {
    my $self = shift;
    my $c = shift;
    _test_city( $c );
    return $self -> {objects} -> {serial}
        == $c -> {objects} -> {serial};
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $revtal = _test_city( $city );

This method performs a sanity check on the value C<$city>.  It returns true if C<$city> is a city or compatable object.  On a negative, this method C<die>s.

=cut

sub _test_city {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects arrayref of Coin objects\n";

    die $e unless ref $c
        and $c -> can( 'coins' )
        and $c -> can( 'country' )
        and $c -> can( 'is_equal' );
    $c;
}

=item $retval = _test_cities( \@cities );

This method is identical to _test_city() but it tests an arrayref of cities instead of a single city.

=cut

sub _test_cities {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects arrayref of City objects\n";

    die $e unless ref( $c ) eq 'ARRAY';
    foreach ( @{ $c } ) {
        die $e unless ref $_
            and $_ -> can( 'coins' )
            and $_ -> can( 'country' )
            and $_ -> can( 'is_equal' );
    }
    $c;
}

=back

=cut

##
# Sort coins into a hash by motif
##

sub _sort_coins {
    my $coins = shift;
    my $c = { };
    map { push @{$c->{$_->motif()}},$_ } @{ $coins };
    return $c;
}

##
# Push hash sorted coins into an array
##

sub _unsort_coins {
    my $c = shift;
    my @coins;
    foreach my $m ( keys %{ $c } ) {
        foreach ( @{ $c -> {$m} } ) {
            push @coins, $_;
        }
    }
    return \@coins;
}

1;
