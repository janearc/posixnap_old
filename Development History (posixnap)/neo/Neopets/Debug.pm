package Neopets::Debug;

use strict;
use warnings;

=head1 NAME

Neopets::Debug - A Debug Facility

=head1 SYNOPSIS

  use Neopets::Debug;

  debug( "an error was found" );

=head1 ABSTRACT

This module is the debug printing
facility for the Neopets:: moduleset.
All debugging messages should be
printed through this facility.

=head1 METHODS

The following methods are exported:

=over 4

=cut

use vars qw/@ISA @EXPORT $VERSION/;
use Exporter;

@ISA = qw/Exporter/;
@EXPORT = qw/debug fatal/;
$VERSION = 0.01;

=item debug( $message );

Displays a debug message with
other apropriate information.

=cut

sub debug {
    my @arr = ( caller(0))[0,1,2,3];
    my $caller = ( caller(1))[3];
    my $debug =  eval "\$$arr[0]::DEBUG";
    $debug and print STDERR "$arr[1]: $caller line $arr[2]: '@_'\n";
    1;
}

=item fatal( $message );

This is similar to debug() but
abruptly exits the program when
run.

=cut

sub fatal {
    my @arr = ( caller(0))[0,1,2,3];
    my $caller = ( caller(1))[3];
    print STDERR "$arr[1]: $caller line $arr[2]: '@_'\n";
    exit 1;
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
