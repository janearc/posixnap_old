package Neopets::Config::CD_Parse;

use constant ID => 0;

use strict;
use warnings;
use Exporter;

use Neopets::Debug;

=head1 NAME

Neopets::Config::CD_Parse - Colon-delimited file parser

=head1 SYNOPSIS

  use Neopets::Config::CD_Parse;

  my $c = parse_cd( \@lines );
  my $file = parse_cd( $c );

=head1 ABSTRACT

This module exports functions for use in parsing
colon-delimited lists.  It currently understands
two formats of files.  The first file is a flat
and simple list:

    Orn Codestone:3999:2
    Bri Codestone:4999:4

When reading this format, the first column recieves
a 'name' key and each aditional column gets a numeric
value, starting with 0.  It is recommended that every
line have the same number of columns.

The second file format specifies a version number
and some information about the values in the columns:

    #2
    item:name:price:quantity
    Orn Codestone:3999:2
    Bri Codestone:4999:4

The first line contains the version number (#2).
As of the writing of this, #2 is the highest version.
The next line contains column names.  The first
field contains a name for the items contained.
This file will generate a hash that looks like this:

  {
    version => 2,
    item => {
              'Orn Codestone' => {
                                   price => 3999,
                                   quantity => 2,
                                 },
              'Bri Codestone' => {
                                   price => 4999,
                                   quantity => 4,
                                 },
            },
  }

  The second format is ideal, the first is only added
  for backwards compatability and will be removed asap.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use vars qw/ @ISA $VERSION @EXPORT /;

@ISA = qw/Exporter/;
$VERSION = 0.01;
@EXPORT = qw/parse_cd write_cd/;

=item parse_cd( \@file );

The parse function takes a file (split by '\n') and
attempts to convert it into the hash shown above.
When given an old file (not #2) it will complain
but attempt to dtrt.

=cut

sub parse_cd {
  my @lines = @{ shift() };

  my @columns;
  my ( $name, $version );
  my %config = ( );

  if ( substr($lines[0], 0, 2) eq '#2' ) {
    $version = 2;
    chomp $lines[1];
    my @line = split ':', $lines[1];
    ( $name, @columns ) = @line;
    foreach ( 1 .. 2) { shift @lines }
  } else {
    my @line = split ':', $lines[0];
    @columns = ( 0 .. @line-1 );
  }

  foreach ( @lines ) {
    my $input = $_;
    chomp $input;

    my @line = split ':', $input;

    if( $config{ $line[ ID ] } )
      { die "$0: read_input: Syntax error, duplicate item : $line[ID]\n" }

    my %tmp = ( );
    foreach my $id ( 1 .. @line-1 ) {
      $tmp{ $columns[$id] } = $line[$id];
    }

    $config{ $line[ ID ] } = \%tmp;
  }

  return \%config unless ( $name );
  return { version => $version, $name => \%config };
}

=item write_cd( \%hash );

This function takes the hash displayed in
the ABSTRACT and forms a #2 version cd file
out of it.  It takes a hash reference and
returns a scalar representing the file
to be written.

=cut

sub write_cd {
  my $contents = shift;

  unless ( $contents -> {version} ) {
    debug( "this version is unknown, i cannot write this" );
    return;
  }

  my ( $version, $cat, $heading, $file );
  foreach my $key ( keys %{ $contents } ) {
    if ( $key eq 'version' ) {
      $version = $contents -> {$key};
    } elsif ( $key eq 'date' ) {
      # do nothing
    } else {
      $cat = $key;
    }
  }

  foreach my $key ( keys %{ $contents -> {$cat} } ) {
    my $line = $key;
    $heading = "$cat:name";
    foreach my $entry ( keys %{ $contents -> {$cat} -> {$key} } ) {
      $line = "$line:".$contents -> {$cat} -> {$key} -> {$entry};
      $heading = "$heading:$entry";
    }
    unless ( $file ) {
      $file = "#$version\n$heading\n"; }
    $file = "$file$line\n";
  }

  return $file;
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
