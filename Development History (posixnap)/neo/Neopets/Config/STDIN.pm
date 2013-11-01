package Neopets::Config::STDIN;

use strict;
use warnings;
use Neopets::Config::CD_Parse;
use Exporter;

=head1 NAME

Neopets::Config::STDIN - stdin/out submodule for Neopets::Config

=head1 SYNOPSIS

  use Neopets::Config;

  my $config = Neopets::Config -> new();

  my $c = $config -> read_config( { STDIN => 1 } );

  $config -> write_config( { STDIN => 1, contents -> $c } );

=head1 ABSTRACT

This module provides the capability for CLI
config file entry for Neopets::Config.  It
should never be used directly, only through
its parent Neopets::Config.

Setting STDIN => $true in the argument hash
specifies use of this module.  No unstandard
options are required for use.

=cut

use vars qw/ @ISA $VERSION @EXPORT /;

@ISA = qw/Exporter/;
$VERSION = 0.01;
@EXPORT = qw/read_sub_config write_sub_config/;

sub read_sub_config {
  print "Begin input:\n";
  my @lines = <>;
  return parse_cd( \@lines );
}

sub write_sub_config {
  my ( $args ) = @_;

  my $contents = $args -> {contents};
  my $file = write_cd( $contents );

  print "BEGIN FILE\n";
  print "$file";
  print "END FILE\n";
}

1;

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
