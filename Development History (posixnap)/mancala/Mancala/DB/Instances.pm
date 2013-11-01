package Mancala::DB::Instances;

use strict;
use warnings;
use Mancala::DB::Agent;
use Mancala::DB::Simple;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::DB::Simple/;

=head1 NAME

Mancala::DB::Instances - Instance table interface

=head1 ABSTRACT

 # create an instance object
 use strict;
 use Mancala::DB::Instances;

 my $inst = Mancala::DB::Instances -> new();

=head1 SYNOPSIS

=head1 METHODS

The following methods are provided:

=over 4

=item my $inst = Mancala::DB::Instances -E<gt> new();

This method returns an instance object.

=cut

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    return bless {
        objects => {
            agent => Mancala::DB::Agent -> new(),
        },
    }, $this;
}

=item $count = $inst -E<gt> get_all_instance_count( $agent_id );

This method returns the number of instances inserted by the agent with id C<$agent_id>.  If the instance count is 0, this method return 1.  This avoids a divide by 0 error and doesn't effect the operation of the bayes classifier that uses this.  This way, 0 / 0 will evaluate as 0 ( 0 / 1 ).

=cut

sub get_all_instance_count {
    my $dbh = shift() -> {objects} -> {agent} -> dbh();
    my $agent_id = shift;

    my $sth = $dbh -> prepare( "select count(*) from instances where agent_id = ?" )
        or die "Could not prepare statement: ".DBI->errstr;
    $sth -> execute( $agent_id )
        or die "Could not execute statememt: ".DBI->errstr;
    my @arr = $sth -> fetchrow_array();
    $sth -> finish();

    return $arr[0] || 1;
}

=item $count = $inst -E<gt> get_instance_count( $agent_id, $instance, ... );

This method returns the number of entries matching all of the given instance(s).

=cut

sub get_instance_count {
    my $self = shift;
    my $agent_id = shift;
    my @instance = @_;

    my $agent = $self -> {objects} -> {agent};
    my $dbh = $agent -> dbh();

    #print $agent -> freeze( \@instance ), "\n";
    #die "";

    my $sth = $dbh -> prepare(
        "select count(*) from instances
            where agent_id = ? and value = ?" )
        or die "Could not prepare statement: ".DBI->errstr;

    $sth -> execute( $agent_id, $agent -> freeze( \@instance ) )
        or die "Could not execute statememt: ".DBI->errstr;
    my @arr = $sth -> fetchrow_array();
    $sth -> finish();

    return $arr[0];
}

=item $count = $inst -E<gt> get_class_count( $agent_id, $class );

This method returns the number of entries matching the given class.

=cut

sub get_class_count {
    my $self = shift;
    my $agent_id = shift;
    my $class = shift;

    my $agent = $self -> {objects} -> {agent};
    my $dbh = $agent -> dbh();

    if ( ref $class )
        { $class = $agent -> freese( $class ) }

    my $sth = $dbh -> prepare(
        "select count(*) from instances
            where agent_id = ? and class = ?" )
        or die "Could not prepare statement: ".DBI->errstr;

    $sth -> execute( $agent_id, $class )
        or die "Could not execute statememt: ".DBI->errstr;
    my @arr = $sth -> fetchrow_array();
    $sth -> finish();

    return $arr[0];
}

=item $count = $inst -E<gt> get_instance_given_class_count( $agent_id, $class, $instance, ... );

This method returns the number of instances matching the given instance and one particular class.

=cut

sub get_instance_given_class_count {
    my $self = shift;
    my $agent_id = shift;
    my $class = shift;
    my @instance = @_;

    my $agent = $self -> {objects} -> {agent};
    my $dbh = $agent -> dbh();

    if ( ref $class )
        { $class = $agent -> freeze( $class ) }

    my $sth = $dbh -> prepare(
        "select count(*) from instances
            where agent_id = ? and class = ?
            and value = ?" )
        or die "Could not prepare statement: ".DBI->errstr;

    $sth -> execute( $agent_id, $class, $agent -> freeze( \@instance ) )
        or die "Could not execute statememt: ".DBI->errstr;
    
    my @arr = $sth -> fetchrow_array();
    $sth -> finish();

    return $arr[0];
}

=item @classes = @{ $inst -E<gt> get_classes( $agent_id ) };

This method returns an arrayref of the classes added by the agent with id C<$agent_id>.

=cut

sub get_classes {
    my $dbh = shift() -> {objects} -> {agent} -> dbh();
    my $agent_id = shift;

    my $sth = $dbh -> prepare(
        "select distinct class from instances
            where agent_id = ?" )
        or die "Could not prepare statement: ".DBI->errstr;

    $sth -> execute( $agent_id );

    my $class_ref = $sth -> fetchall_arrayref();
    my @classes = map { @{ $_ } } @{ $class_ref };

    return \@classes;
}

=item $inst -E<gt> add( $agent_id, $class, %data );

This method adds an instance into the database wit hthe given information.

=cut

sub add {
    my $self = shift;
    my $agent_id = shift;
    my $class = shift;
    my %data = @_;

    my $agent = $self -> {objects} -> {agent};
    my $dbh = $agent -> dbh();

    my $sth = $dbh -> prepare( "insert into instances values ( ?, ?, ?, ? )" )
        or die "Could not prepare statement: ".DBI->errstr;

    while ( my @d = each %data ) {
        $sth -> execute(
                $agent -> next_key( 'instances' ), $agent_id,
                $class, $agent -> freeze( \@d ) )
            or die "Could not execute statememt: ".DBI->errstr;
    }

    $sth -> finish();
}

=back

=cut

1;
