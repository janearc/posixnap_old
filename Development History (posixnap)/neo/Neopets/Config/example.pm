package Neopets::Config::example;

use strict;
use warnings;
use Exporter;

=head1 NAME

Neopets::Config::example - Example config module

=head1 SYNOPSIS

  # empty module contents

  use strict;
  use warnings;
  use Exporter;

  use vars qw/ @ISA $VERSION @EXPORT /;

  @ISA = qw/Exporter/;
  $VERSION = 0.01;
  @EXPORT = qw/read_sub_config write_sub_config/;

  sub read_sub_config {
    # read a config file
  }

  sub write_sub_config {
    # write a config file
  }

  1;

=head1 ABSTRACT

This is an example module for use with Neopets::Config. 
Neopets::Config is designed to use arbitrary modules for reading
and writing config files.  All that is required is the module
fit a standard API and does not do anything naughty.  These
modules are only loaded if needed meaning requirenments will
only effect the user attempts to use the feature.  No one at
any time should use these sub modules directly, they should
only be accessed through the Neopets::Config module.

The required API is simple, the submodule must export two
functions, read_sub_config and write_sub_config.

=head1 METHODS

The following methods are required:

=over 4

=cut

use vars qw/ @ISA $VERSION @EXPORT /;

@ISA = qw/Exporter/;
$VERSION = 0.01;
@EXPORT = qw/read_sub_config write_sub_config/;

=item read_sub_config;

This method reads a config file.  There is one
parameter that this function will always be
passed.  It comes in the form of a hash:
  { $method => $file }
$method will be the case sensative module name
and $file will usully be the source file relative
to $ENV{NP_HOME}.  All other key => name pairs in
the hash are optional.

=cut

sub read_sub_config {
  # read a config file
}

=item write_sub_config;

This method writes a config file.  Two parameters
are usually passed to this function in a hash:
  { file => $file,
    contents => $contents }
$file is usually a filename relative to $ENV{NP_HOME}
and $contents is the content to be written.  Other
optional module specific arguments may be required
by the programmer.

=cut

sub write_sub_config {
  # write a config file
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
