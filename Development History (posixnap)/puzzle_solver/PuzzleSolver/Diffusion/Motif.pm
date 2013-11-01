package PuzzleSolver::Diffusion::Motif;

use strict;
use warnings;
use Exporter;

use vars qw/@ISA $VERSION @EXPORT_OK %EXPORT_TAGS/;

$VERSION = 0.01;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_test_motif/;
%EXPORT_TAGS = (
    'checks' => \@EXPORT_OK
);

=head1 NAME

PuzzleSolver::Diffusion::Motif - A Motif or Nationality object

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Diffusion::Motif;

 my $motif = PuzzleSolver::Diffusion::Motif -> new(
    name => "foobar" );
 
 print $motif -> name(), "\n";

=head1 ABSTRACT

This module represents a motif or nationality.  Designed to represent one devision of the country specific euros districuted and used within many europian countries, this is ment to be a simple name holder allowing for easy comparison between objects of the same motif.  It has no specific functionality beyond a C struct.

=head1 METHODS

The following methods are provided:

=over 4

=item $motif = PuzzleSolver::Diffusion::Motif -E<gt> new( %args );

This method creates and returns a Motif object.  This method takes optional args in hash form.  Args are as such:

  KEY           DEFAULT
  --------      --------
  name          undef
  country       undef

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    my %args = @_;

    my $name = $args{name};
    my $country = $args{country};

    return bless {
        objects => {
            name => $name,
            country => $country,
            serial => rand 10000,
        },
    }, $this;
}

=item $name = $motif -E<gt> name( $name );

This method returns the name of the motif.  If the motif is without a name, then this returns undef.  Optionally, this also takes a scalar name to set the name of the motif.  In this case, this returns the argument name.

=cut

sub name {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {name} = shift;
    }
    return $self -> {objects} -> {name};
}

=item $country = $motif -E<gt> country( $country );

This method returns the country from which this motif originates from.  If unset, this returns undef.  Optionally whis value can be set by passing a scalar reference to a country.

=cut

sub country {
    my $self = shift;
    if ( @_ ) {
        $self -> {objects} -> {country} = shift;
    }
    return $self -> {objects} -> {country};
}

=item $bool = $motif -E<gt> is_equal( $other_motif );

This method returns true if C<$motif> and C<$other_motif> are the same, C<undef> otherwise.  This is done by comparing a random serial number contained with every motif, generated once upon creation.

=cut

sub is_equal {
    my $self = shift;
    my $m = shift;
    _test_motif( $m );
    return $m -> {objects} -> {serial}
        == $self -> {objects} -> {serial};
}

=back

=cut

=head1 EXPORTS

The following methods are optionally exported by this module:

=over 4

=item $retval = _test_motif( $motif );

This method performs a sanity check on the value C<$motif>.  It returns true if C<$motif> is a Motif or compatable object.  On a negative, this method C<die()>s.

This is also exported with the export tag C<:checks>.

=cut

sub _test_motif {
    my $m = shift;
    my ($x, $y, $z, $sub) = caller(1);
    my $e = "Die: $sub(): expects Motif object\n";
    die $e unless ref $m
        and $m -> can( 'name' )
        and $m -> can( 'country' )
        and $m -> can( 'is_equal' );
    $m;
}

=back

=cut

1;
