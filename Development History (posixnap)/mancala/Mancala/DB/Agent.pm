package Mancala::DB::Agent;

use constant AGENT => "agent";
use constant AGENT_PW => "12345";

use strict;
use warnings;
use DBI;
use FreezeThaw;

# this will be the handle, don't touch it.
our $DBH;

=head1 NAME

Mancala::DB::Agent - Database Agent

=head1 SYNOPSIS

 # create an agent object
 use strict;
 use Mancala::DB::Agent;

 my $agent = Mancala::DB::Agent -> new();

 my $dbh = $agent -> dbh();

 my $str1 = $agent -> freeze( { foo => bar } );
 my $sth2 = $agent -> freeze( [ 1, 2, 3 ] );

 my %hash = %{ $agent -> thaw( $str1 ) };
 my @arr = @{ $agent -> thaw( $sth2 ) };

 my $key = $agent -> next_key( 'instances' );

=head1 ABSTRACT

This module is an agent to the database.  It will return a database handle when requested and also return the next available key for any given table.  This also has methods for adjusting complex data structures into enteties that can be stored in a database.

No more than one database handle will be opened for each agent object.  This object will also ensure that the handle is destroyed correctly.

=head1 METHODS

The following methods are provided:

=over 4

=item new $agent = Mancala::DB::Agent -E<gt> new();

This method returns an agent object.

=cut

sub new {
    return bless { }, shift;
}

sub DESTROY {
    if ( defined $DBH ) {
        $DBH -> disconnect();
        $DBH = undef;
    }
}

=item $dbh = $agent -E<gt> dbh();

This method returns a database handle.

=cut

sub dbh {
    unless ( $DBH ) {
        $DBH
            = DBI -> connect( "dbi:Pg:dbname=mancala_learner", AGENT(), AGENT_PW() )
                or die "Could not connect to the database: ".DBI->errstr;
    }
    return $DBH;
}

=item $key = $agent -E<gt> next_key( $table );

This method returns the next available key in the named table.

=cut

sub next_key {
    shift;
    my $table = shift;
    my $dbh = dbh();
    my @arr = $dbh -> selectrow_array( "select max(key) from $table" )
        or die "table does not exist or does not have a key field: ".DBI->errstr;
    return $arr[0]
        ? $arr[0] + 1
        : 1;
}

=item $str = $agent -E<gt> freeze( $something, ... );

This method turns its arguments into a single string that can be stored in a database.

=cut

sub freeze {
    shift;
    return FreezeThaw::freeze shift();
}

=item $something = $agent -E<gt> thaw( $str );

This method turns a stringified data structure back into the original structure.

=cut

sub thaw {
    shift;
    return FreezeThaw::thaw shift();
}

=back

=cut

1;
