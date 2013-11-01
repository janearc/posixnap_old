package Neopets::HTML::Table;

use strict;
use warnings;

use Exporter;
use Neopets::Agent;
use Neopets::Debug;
use Neopets::HTML;
use HTML::TableContentParser;

# debug flag
our $DEBUG;

# object to parse tables
my $table_parser = HTML::TableContentParser -> new();

=head1 NAME

=head1 SYNOPSIS

=head1 ABSTRACT

=head1 METHODS

The following methods are exported:

=over 4

=cut

use vars qw/@ISA @EXPORT $VERSION/;

@ISA = qw/Exporter/;
@EXPORT = qw/get_tables parse_table parse_table_quick/;
$VERSION = 0.01;

=item my @table = @{ get_tables( { page => $page } ) };

This method takes a $page and generates
a datastructure from this page representing
the tables.

=cut

sub get_tables {
  my ( $args ) = @_;

  my $page = $args -> {page}
    || fatal( "must supply page" );

  my $tables = $table_parser -> parse( $page );

  return $tables;
}

=item $table = @{ $table -> parse_table( { table => $table } );

This takes a table as given by parse() and
attempts to turn it into name => value pairs
by row.

If { strip => 1 } is included in the
parameter hashref, all html tags
will be stripped out of the output.

=cut

sub parse_table {
    my ( $args ) = @_;

    my $table = $args -> {table}
      || fatal( "must supply table" );
    
    my $strip = $args -> {strip};

    my @rows;
    foreach my $cell ( @{ $table -> {rows} } ) {
        my $heading = shift( @{ $cell -> {cells} } ) -> {data};
        if ( $strip ) { $heading =~ s/<.*?>//sg }
        my @contents;
        while ( my $slice = shift @{ $cell -> {cells} } ) {
            if ( $strip )
                { $slice -> {data} =~ s/<.*?>//sg }
            push @contents, $slice -> {data};
        }

        push @rows, { $heading => \@contents };
    }

    return \@rows;
}

=item @table = @{ parse_table_quick( { page => $page } ) };

This method encorporates the other
methods of this module in one
somple step.  Generates a list of
rows out of $page.  This only works when
there is only one table to parse.  If
there is more than one, only the first
is parsed.

Cleans the page using Neopets::HTML.

=cut

sub parse_table_quick {
    my ( $args ) = @_;

    my $page = $args -> {page}
        || fatal( "must supply page" );

    $page = clean_html( { page => $page } );

    return parse_table(
        { table => ${ get_tables( { page => $page } ) }[0],
          strip => $args -> {strip} || 0,
        } );
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
