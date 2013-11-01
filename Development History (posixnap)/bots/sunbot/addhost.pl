#!/usr/local/bin/perl

use warnings;
use strict;
use DBI;

$|++;

my $dbh = DBI->connect("dbi:Pg:dbname=sys_monitor;host=172.17.54.254", "tyler");


my $host = shift(@ARGV);

unless (gethostbyname($host)) { die ("Could not resolve $host check DNS and try again.\n") }

$dbh->do(qq{ create table $host ( 
    	      stamp timestamp default now(),
	      id serial,
	      uptime varchar(64),
	      load varchar(64),
	      mounts varchar(1024),
	      mem varchar(64),
	      cpu varchar(64),
	      primary key (id)
	      )});


$dbh->disconnect();
