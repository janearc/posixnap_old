package Neopets::Config;

use strict;
use warnings;

use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

Neopets::Config - A configuration reader/writer

=head1 SYNOPSIS

  # creating a config object and using it to
  # read/write config files in $NP_HOME/

  use Neopets::Config;
  use Data::Dumper;

  my $config = Neopets::Config -> new();

  my $file =
      $config -> read_config( { XML => 'wizard.xml' } );

  print Dumper $file;

  $config -> write_config( {
                             file => 'wizard.xml',
			     contents => $file,
			     root => 'wizard-search-list',
                         } );

=head1 ABSTRACT

This module reads and writes config files for use with
the Neopets::* module suite.  It allows for simple
configuration methods to be added and removed at runtime
(see Neopets/Config/example.pm).

This module requires that a variable NP_HOME be set in order to function.
This should be the path to a writable directory in which this toolkit
can store information.

=head1 METHODS

The following methods are provided:

=over 4

=cut

no strict 'refs';
use vars qw/ @ISA $VERSION /;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

=item $config = Neopets::Config->new;

The constructor takes no arguments and returns
an object of type Neopets::Config.

=cut

sub new {
  my $that = shift;
  my $this = ref( $that ) || $that;

  my ( $args ) = @_;

  $DEBUG = $args -> {debug};

  return bless { }, $this;
}

=item $config->read_config( { $method => $file } );

This method reads a configure file using
$method, where $method is the name of a
Neopets::Config::* module (ie. XML for
Neopets::Config::XML or Text for
Neopets::Config::Text).  This returns a
hashref representing the contents of the
file.  Returns nothing if there was an
error.

This method takes a docroot hashparam
in order to specify a location to search
for files outside of $NP_HOME.

=cut

sub read_config {
  my $self = shift;
  my ( $args ) = @_;

    # this is here for backwards compatability
  if ( $args -> {file} ) {
    if ( $args -> {file} =~ /\.xml$/ ) {
      require Neopets::Config::XML;
      return Neopets::Config::XML::read_sub_config( { XML => $args -> {file}, %{ $args } } );
    } else {
      require Neopets::Config::Text;
      return Neopets::Config::Text::read_sub_config( { Text => $args -> {file}, %{ $args } } );
    }
  }

    # load modules and set $facility to config facility
  my $facility;
  foreach my $mod ( keys %{ $args } ) {
    debug( "Attemting to load 'Neopets/Config/$mod.pm'" );
    if ( eval { require "Neopets/Config/$mod.pm" } ) {
      debug( "'Neopets/Config/$mod.pm' successfully loaded" );
      $facility = $mod;
    } elsif ( defined &{ "Neopets::Config::".$mod."::read_sub_config" } ) {
      debug ( "'Neopets/Config/$mod.pm' already loaded\n" );
      $facility = $mod;
    }
  }

  debug( "Using facility : $facility" );

    # make sure there was a valid facility set
  unless ( $facility ) {
    warn "$0: read_config: no config facility specified\n";
    warn "      make sure that a valid facility was entered\n";
    warn "      and that facility compiles.  try:\n";
    warn "       perl -e 'use Neopets::Config::facility'\n";
    exit 1;
  }

    # run the function in that facility
  return &{ 'Neopets::Config::'.$facility.'::read_sub_config' }( $args );
}

=item $config->write_config(
  { $method => $file,
    contents => $contents,
  } );

Writes a config file using the arguments
supplied in hash style.  $method and contents
are both required (see read_config() for
details about $method).  Any other arguments
will be passed to the sub module specified
by $method (ie. root => 'wizard-search-list
tells XML::Simple the root name).

=cut

sub write_config {
  my $self = shift;
  my ( $args ) = @_;

  my $facility;
  foreach my $mod ( keys %{ $args } ) {
    debug( "Attemting to load 'Neopets/Config/$mod.pm'" );
    if ( eval { require "Neopets/Config/$mod.pm" } ) {
      debug( "'Neopets/Config/$mod.pm' successfully loaded" );
      $facility = $mod;
    } elsif ( defined &{ "Neopets::Config::".$mod."::write_sub_config" } ) {
      debug( "'Neopets/Config/$mod.pm' already loaded" );
      $facility = $mod;
    }
  }

  debug( "Using facility : $facility" );

    # make sure there was a valid facility set
  unless ( $facility ) {
    warn "$0: write_config: no config facility specified\n";
    warn "      make sure that a valid facility was entered\n";
    warn "      and that facility compiles.  try:\n";
    warn "       perl -e 'use Neopets::Config::facility'\n";
    exit 1;
  }

     # run the function in that facility
  return &{ 'Neopets::Config::'.$facility.'::write_sub_config' }( $args );
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

