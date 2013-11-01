#!/usr/bin/perl -w

# configurable information
use constant SUPER_USER => "postgres";
use constant SU_PW => "";
use constant AGENT_PASSWORD => "12345";

use strict;
use warnings;
use DBI;
use DBD::Pg;

# tables and users to create
my @tables = qw/policy instances/;
my @users = qw/agent/;

# connect as the super user
my $dbh = DBI -> connect( "dbi:Pg:dbname=mancala_learner", SUPER_USER(), SU_PW() )
    or die "This script could not connect to the database, make sure you are connecting to the right database and as the database super user: ".DBI->errstr;

print "Connected to database\n";
print "The next step may cause errors, ignore them.\n";
print "Dropping old tables (if they exist)\n";

# go ahead and drop all the tables, ignore errors
foreach my $t ( @tables ) {
    eval { $dbh -> do( "drop table $t" ) };
}

foreach my $u ( @users ) {
    eval { $dbh -> do( "drop user $u" ) };
}

$dbh -> do( "create user agent password '".AGENT_PASSWORD()."'" )
    or die "Could not create user 'agent'\n";

print "Added user 'agent' with password '".AGENT_PASSWORD()."'\n";

# this is a better table but its slow, we want speeeed
#$dbh -> do( "create table policy ( key int primary key, agent_id int not null, configuration varchar not null unique, action int not null )" )
$dbh -> do( "create table policy ( key int, agent_id int not null, configuration varchar not null, action int not null )" )
    or die "Could not create table 'policy'\n";

print "Created policy table\n";

# see the above mention of speeeed
#$dbh -> do( "create table instances ( key int primary key, agent_id int not null, class int not null, value varchar not null ) " )
$dbh -> do( "create table instances ( key int, agent_id int not null, class int not null, value varchar not null ) " )
    or die "Could not create table 'instances'\n";

print "Created instances table\n";

foreach my $t ( @tables ) {
    $dbh -> do( "grant select, insert, update, delete on $t to agent" );
    $dbh -> do( "revoke all on table $t from public" );
}

print "Permissions set\n";

$dbh -> disconnect();
