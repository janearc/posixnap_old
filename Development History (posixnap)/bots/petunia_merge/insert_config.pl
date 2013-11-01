#!/usr/bin/perl

use DBI;
use warnings; use strict;

my $dbh = DBI -> connect("dbi:Pg:dbname=botdb_elvis", "alex", "");
my $sth = $dbh -> prepare(qq{
	insert into config (key, value) values (?, ?)
});
my %config = ( qw{
nick petunia
port 6667
server irc.posixnap.net 
db_user alex
dsn dbi:Pg:dbname=botdb_elvis
max_dbh 6
admin_channel padmin
moddir components
channel #posix
} );

foreach my $key (keys %config) {
	$sth -> execute($key, $config{$key});
}
END { $dbh -> disconnect() }
