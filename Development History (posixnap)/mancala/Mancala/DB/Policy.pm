package Mancala::DB::Policy;

use constant NUM_CUPS => 12;
use constant MAX_STONES => 1;

use strict;
use warnings;
use List::Util qw/shuffle/;
use Mancala::DB::Agent;
use Mancala::DB::Simple;

use vars qw/@ISA $VERSION/;

$VERSION = 0.01;
@ISA = qw/Mancala::DB::Simple/;

# this is a default encoding for a board instance
# it cuts down on the number of instances needed
our $ENCODE_MAP = { '0' => '0', rest => 1 };

sub new {
    my $that = shift;
    my $this = ref( $that ) || $that;

    return bless {
        objects => {
            agent => Mancala::DB::Agent -> new(),
        },
    }, $this;
}

sub get {
    my $self = shift;
    my $agent_id = shift;
    my $configuration = shift;

    my $agent = $self -> {objects} -> {agent};
    my $dbh = $agent -> dbh();

    if ( ref $configuration ) {
        $configuration = $agent -> freeze( $configuration );
    }

    my $sth = $dbh -> prepare( "select action from policy where configuration = ? and agent_id = ?" )
        or die "Could not prepare statement: ".DBI->errstr;
    $sth ->execute( $configuration, $agent_id )
        or die "Could not execute statement: ".DBI->errstr;
    my $arr = $sth -> fetchrow_arrayref();
    $sth -> finish();

    return $arr -> [0];
}

sub set {
    my $self = shift;
    my $agent_id = shift;
    my $configuration = shift;
    my $action = shift;

    my $agent = $self -> {objects} -> {agent};
    my $dbh = $self -> {objects} -> {agent} -> dbh();

    if ( ref $configuration ) {
        $configuration = $agent -> freeze( $configuration );
    }

    if ( defined $self -> get( $agent_id, $configuration ) ) {
        my $sth = $dbh -> prepare( "update policy set action = ? where agent_id = ? and configuration = ?" )
            or die "Could not prepare statement: ".DBI->errstr;
        $sth -> execute( $action, $agent_id, $configuration )
            or die "Could not execute statement: ".DBI->errstr;
        $sth -> finish();
    } else {
        my $sth = $dbh -> prepare( "insert into policy values ( ?, ?, ?, ? )" )
            or die "Could not prepare statement: ".DBI->errstr;
        $sth -> execute( 
                $self -> {objects} -> {agent} -> next_key( "policy" ),
                $agent_id, $configuration, $action )
            or die "Could not execute statement: ".DBI->errstr;
        $sth -> finish();
    }
}

sub randomize {
    my $self = shift;
    my $agent_id = shift;
    my $cups = shift || NUM_CUPS();
    my $stones = shift || MAX_STONES();

    # grab some important stuff
    my $agent = $self -> {objects} -> {agent};
    my $dbh = $agent -> dbh();

    # remove all the old policies
    my $sth = $dbh -> prepare( "delete from policy where agent_id = ?" );
    $sth -> execute( $agent_id );

    # prepare a statement to wear out
    $sth = $dbh -> prepare( "insert into policy values ( ?, ?, ?, ? )" );

    my @cups;
    foreach ( 1 .. $cups-1 ) {
        $cups[$_] = 0;
    }
    $cups[0] = 1;

    my $bool = 1;
    while ( $bool ) {

        # add to the database
        # print "@cups\n";   # debug

        $sth -> execute(
            $agent -> next_key( "policy" ), $agent_id,
            $agent -> freeze( \@cups ), (shuffle( grep { $cups[$_] } ( 0 .. @cups-1) ) )[0] ); 

        # add one
        $cups[0]++;

        # carry
        my $i = 0;
        while ( $cups[$i] > $stones ) {
            $cups[$i] = 0;
            $i++;
            $cups[$i]++;

            # catch the end, do it here so its nto evaled every time
            if ( $cups[$cups-1] == $stones ) {
                my $sum = 0;
                foreach ( @cups )
                    { $sum += $_ }
                $bool = 0 if $sum >= $stones * $cups;
            }
        }
    }

    $sth -> finish();
}

sub encode_instance {
    my $self = shift;
    my $instance = shift;
    my $encode_map = shift || $ENCODE_MAP;

    # encode each cup
    foreach my $cup ( keys %{ $instance } ) {
        my $encoded = undef;
        foreach my $key ( keys %{ $encode_map } ) {
            if ( ($instance -> {$cup} eq $key) and not $encoded ) {
                $instance -> {$cup} = $encode_map -> {$key};
                $encoded = 1;
            }
        }
        $instance -> {$cup} = $encode_map -> {'rest'}
            unless $encoded;
    }

    return $instance;
}

1;
