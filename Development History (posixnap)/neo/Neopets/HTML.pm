package Neopets::HTML;

use strict;
use warnings;

use Exporter;
use Neopets::Debug;

# debug flag
our $DEBUG;

=head1 NAME

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 METHODS

The following methods are exported:

=over 4

=cut

use vars qw/@ISA @EXPORT $VERSION/;

@ISA = qw/Exporter/;
@EXPORT = qw/clean_html/;
$VERSION = 0.01;

=item $page = clean_html( { page => $page } );

=cut

sub clean_html {
  my ( $args ) = @_;

  my $page = $args -> {page}
    || fatal( "an html page must be passed" );

  # remove unwanted cruft and useless tags
  # take only the body
  # this is a s!!! because the body tags might not exist
  $page =~ s!<body[^>]*>(.*)</body>!$1!sig;
  # remove the header
  $page =~ s!.*</map>..</center>!!sig;
  # we don't need comments
  $page =~ s/<!--.*?-->//sig;
  # scripts are useless
  $page =~ s!<script.*?script>!!sig;
  # empty all one char tags
  $page =~ s!<[/]?.>!!sig;
  # kill <br>
  $page =~ s/<br>/ /sig;
  # fix spaces
  $page =~ s/&nbsp;/ /ig;
  $page =~ s/>\s+/>/sig;
  $page =~ s/\s+</</sig;

  return $page;
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
