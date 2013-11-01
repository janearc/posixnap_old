#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;

use PuzzleSolver::Diffusion::Agent;
use PuzzleSolver::Diffusion::IO;

my $agent = PuzzleSolver::Diffusion::Agent -> new();
my $io = PuzzleSolver::Diffusion::IO -> new();

my @worlds = @{ $io -> input() };

foreach my $i ( 1 .. @worlds ) {
    my $world = $worlds[$i-1];
    my %countries;
    my $ticks = 0;
    foreach ( @{ $world -> countries() } ) {
        $countries{$_} = undef;
    }

    $agent -> world( $world );

    while ( not test_complete( $agent, \%countries, $ticks ) ) {
        $agent -> diffuse() and $ticks++;
    }
    
    print "Case Number $i\n";
    map {
        print "   $_\t$countries{$_}\n" } sort {
            $countries{$a} eq $countries{$b}
                ? $a cmp $b
                : $countries{$a} <=> $countries{$b} } keys %countries;
}

exit;

sub test_complete {
    my $agent = shift;
    my $countries = shift;
    my $ticks = shift;
    foreach ( keys %{ $countries } ) {
        if ( not( $countries -> {$_} ) and $agent -> world() -> complete( country => $_ ) ) {
            $countries -> {$_} = $ticks;
        }
    }
    foreach ( keys %{ $countries } ) {
        return unless defined $countries -> {$_};
    }
    return 1;
}
