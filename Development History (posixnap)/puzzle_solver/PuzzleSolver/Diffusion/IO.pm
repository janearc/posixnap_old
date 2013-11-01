package PuzzleSolver::Diffusion::IO;

use strict;
use warnings;
use PuzzleSolver::Diffusion::World;

=head1 NAME

PuzzleSolver::Diffusion::IO - I/O module for Diffusion

=head1 SYNOPSIS

 use strict;
 use PuzzleSolver::Diffusion::IO;

 my $io = PuzzleSolver::Diffusion::IO -> new();
 
 my @worlds = @{ $io -> input() };

=head1 ABSTRACT

=head1 METHODS

The following methods are provided:

=over 4

=item $io = PuzzleSolver::Diffusion::IO -E<gt> new();

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    return bless { }, $this;
}

=item @worlds = @{ $io -E<gt> input() };

=cut

sub input {
    my @w = ( );
    while ( my $c = <> ) {
        return \@w if $c == 0;
        my $world = PuzzleSolver::Diffusion::World -> new( name => scalar @w );
        die "IO: input: the first input must bhe the number of countryes (1 <= c <= 20)\n"
            unless $c <= 20 and $c >= 1;
        foreach ( 1 .. $c ) {
            my $line = <>;
            my ( $country, $x1, $y1, $x2, $y2 ) = $line =~ m/^(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/;
            die "IO: input: country input is in the format: 'name x1 y1 x2 y2'\n"
                unless $country and $x1 and $x2 and $y1 and $y2;
            $world -> add_country( country_name => $country,
                x1 => $x1, x2 => $x2, y1 => $y1, y2 => $y2,
                motif_name => "$country coins" );
        }
        push @w, $world;
    }

    return \@w;
}

=back

=cut

1;
