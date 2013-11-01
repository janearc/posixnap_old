package PuzzleSolver::Diffusion::Coin;

use strict;
use warnings;
use PuzzleSolver::Diffusion::Motif qw/:checks/;
use Exporter;

use vars qw/@ISA $VERSION @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_coin _test_coins _test_uint_hash_coins _test_uint/;
%EXPORT_TAGS = (
    'checks' => \@EXPORT_OK
);

=head1 NAME

PuzzleSolver::Diffusion::Coin - A single coin object

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Diffusion::Coin;

 my $coin = PuzzleSolver::Diffusion::Coin -> new(
    motif => $motif );

=head1 ABSTRACT

This module is represents a single coin.  This stores minimal coin information and has no specific functionality beyond a C struct.

=head1 METHODS

The following methods are provided:

=over 4

=item $coin = PuzzleSolver::Diffusion::Coin -E<gt> new ( %args );

This method creates and returns a Coin object.  This method takes optional args in hash form.  Args are as such:

  KEY           DEFAULT
  --------      --------
  motif         PuzzleSolver::Diffusion::Motif->new()

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $motif = $args{motif}
        || PuzzleSolver::Diffusion::Motif -> new();

    return bless {
        objects => {
            motif => $motif,
        },
    }, $this;
}

=item $motif = $coin -E<gt> motif( $motif ) {

This method returns the coin's motif.  This will only return a L<Motif object|PuzzleSolver::Diffusion::Motif>.  Optionally, this will also set the coin's motif when passed a motif argument.

=cut

sub motif {
    my $self = shift;
    if ( @_ ) {
        my $m = shift;
        $self -> {objects} -> {motif} = $m;
        _test_motif( $m );
    }
    return $self -> {objects} -> {motif};
}

=item $bool = $coin -E<gt> is_equal( $other_coin );

This method returns true if C<$coin> is equal to C<$other_coin> based on their motifs.  This essentially determines if two coins are of the same nationality.

=cut

sub is_equal {
    my $self = shift;
    my $c = shift;
    _test_coin( $c );
    return $self -> motif() -> is_equal(
        $c -> motif());
}

=back

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_coin( $coin );

This method performs a sanity check on the value C<$coin>.  It returns true if C<$coin> is a Coin or compatable object.  On a negative, this method C<die()>s.

This is also exported with the export tag C<:checks>.

=cut

sub _test_coin {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects Coin object\n";

    die $e unless ref $c
        and $c -> can( 'motif' )
        and $c -> can( 'is_equal' );
    $c;
}

=item $retval = _test_coins( \@coins );

This method is identical to _test_coin() but it tests an arrayref of coins instead of a single coin.

This is also exported with the export tag C<:checks>.

=cut

sub _test_coins {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects arrayref of Coin objects\n";

    die $e unless ref( $c ) eq 'ARRAY';
    foreach ( @{ $c } ) {
        die $e unless ref $_
            and $_ -> can( 'motif' )
            and $_ -> can( 'is_equal' );
    }
    $c;
}

=item $retval = _test_uint_hash_coins( \%coins );

Thius method performs a sanity check on the value C<%coins>.  It returns true if C<%coins> is a hash of unsigned integers, specifying motifs and coins of that motif.  On false, this C<die()>s.

This is also exported with the export tag C<:checks>.

=cut

sub _test_uint_hash_coins {
    my $c = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects hashref of uints\n";

    die $e unless ref( $c ) eq 'HASH';
    foreach ( keys %{ $c } ) {
        die $e unless
            _test_uint( $c -> {$_} );
    }
    $c;
}

=item $retval = _test_uint( $int );

This method performs a sanity check on the value C<$int>.  It returns true if C<$int> is an unsigned integer.  This is mostly used internally by these modules.

This is also exported with the export tag C<:checks>.

=cut

sub _test_uint {
    my $i = shift;
    return unless defined $i;
    return if ref $i;
    return int($i) eq $i
        and $i >= 0;
}

=back

=cut

1;
