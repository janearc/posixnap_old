package Neopets::Common::Wheel;

use strict;
use warnings;
use Neopets::Debug;
use Exporter;

use vars qw/ @ISA $VERSION @EXPORT /;

@ISA = qw/Exporter/;
@EXPORT = qw/common_spin/;
$VERSION = 0.01;

# debug flag
our $DEBUG;
$DEBUG = 0;

=head1 NAME

Neopets::Common::Wheel - Common Wheel Functions

=head1 SYNOPSIS

  use Neopets::Agent;
  use Neopets::Common::Wheel;

  my $agent = Neopets::Agent -> new();

  $result = spin(
    $agent,
    'http://www.neopets.com/faerieland/wheel.phtml',
    'http://www.neopets.com/faerieland/wheel2.phtml',
    'http://www.neopets.com/faerieland/wheel3.phtml'
  );

=head1 ABSTRACT

This is a module for use by other Neopets
modules.  It should never be included
directly.  This is an abstraction of the
spin() method which would be nearly
identical for the Wheel of Excitement,
Wheel of Mediocrity and Wheel of
Misfortune.

=head1 METHODS

The following methods are provided:

=over 4

=item common_spin();

This method takes four arguments.
The first is a Neopets::Agent.
The others are all urls for steps
in the wheel spinning process.
For example, the wheel of excitement
would use:
   \$agent,
  'http://www.neopets.com/faerieland/wheel.phtml',
  'http://www.neopets.com/faerieland/wheel2.phtml',
  'http://www.neopets.com/faerieland/wheel3.phtml'

This returns a string representing
the prize won, or any other response.

=cut

sub common_spin {
  my $agent = shift;
  my @urls = @_;

  $agent -> get( { url => $urls[0] } );

  my $response = 
    $agent -> get( { url => $urls[1], referer => $urls[0] } );

  if ( ( $response =~ "two hours" )
    or ( $response =~ "every fourty minutes" ) ) {
    debug( "You have spun already" );
    return "You have spun already";
  } elsif ( $response =~ "Your account must be at least 48 hours old to use the Wheel of Excitement" ) {
    debug( "You have spun already" );
    return "Oops, your account needs to be two days old to use the WOE.";
  } elsif ( $response =~ "You don't have the" ) {
    debug( "You don't have enough NP" );
    return "You don't have the NP to spin this wheel";
  }

  my ( $prize ) = $response =~ m/name='prize_str' value='([^']+)'>/;
  my ( $pic ) = $response =~ m/name='pic' value='([^']+)'>/;

  my $url = "$urls[2]?prize_str=$prize&subby=";
  $pic and $url = "$url&pic=$pic";
  $agent -> post(
    { url => $urls[2],
      referer => $urls[1],
      params => { prize_str => $prize, subby => '' }, } );

  $prize =~ s/<.*?>//g;

  return "$prize";
}

1;

=back

=head1 SUB CLASSES

See Neopets::Config::

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

