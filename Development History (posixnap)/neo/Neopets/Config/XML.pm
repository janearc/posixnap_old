package Neopets::Config::XML;

use strict;
use warnings;
use Exporter;
use XML::Simple;
use File::Slurp;

=head1 NAME

Neopets::Config::XML - XML::Simple submodule for Neopets::Config

=head1 SYNOPSIS

  use Neopets::Config;

  my $root = 'testing'; # xml root name, defaults to <opt>

  my $c = $config -> read_config( { XML => $file } );
  $config -> write_config( { XML => $file, contents => $c, root => $root } );

=head1 ABSTRACT
XML text configuration files.  It should
never be used directly, only through its
parent Neopets::Config.

Setting XML => $file in the argument hash
specifies use of this module.  This module
can also take a root => name pair for
setting the base XML tag.  This defaults
to <opt> when not specified.  Setting
no_attr => 1 makes the xml output a bit more
extensive but is unnecessary.

=cut

use vars qw/ @ISA $VERSION @EXPORT /;

@ISA = qw/Exporter/;
$VERSION = 0.01;
@EXPORT = qw/read_sub_config write_sub_config/;

sub read_sub_config {
  my ( $args ) = @_;

  my $file = $args -> {XML};
  my $docroot = $args -> {docroot} || $ENV{NP_HOME};

  my $xs = XML::Simple -> new();

  die "$0: read_xml_config_file: $docroot/$file does not exist\n" 
      unless ( -f "$docroot/$file" );

  my $xml = $xs -> XMLin( "$docroot/$file" );

}

sub write_sub_config {
  my ( $args ) = @_;

  my $file = $args -> {XML};
  my $contents = $args -> {contents};
  my $root = $args -> {root} || 'opt';
  my $no_attr = $args -> {no_attr} || '0';
  my $docroot = $args -> {docroot} || $ENV{NP_HOME};

  my $xs = XML::Simple -> new();

  my $xml = $xs -> XMLout( $contents, noattr => $no_attr, rootname => $root  );
  write_file( $docroot."/$file", $xml );
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
