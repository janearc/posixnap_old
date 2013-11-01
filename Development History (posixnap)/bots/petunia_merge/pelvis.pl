#!/usr/local/bin/perl

#
# pelvis.pl
#
# pelvis is the merging of elvis and petunia.
# dan and i never decided on the name "pelvis", but it seemed appropriate.
# 
# Example:
# what, are you kidding? this code does not work. period.
#

use warnings;
use strict;
# mutter
no strict "refs";
our ( $daemon, $debug, %config, );

# debuggery
use Carp qw{ cluck croak carp confess };
use Data::Dumper;
use File::Slurp;
use DBI;

# import poe stuff
use POE;
use POE::Kernel;
use POE::Component::IRC;

# Prepare our data storage
use Broker::Config;
use Broker::NVStorage;

use utility;
use utility::communication;
use utility::control;

# setup the bot
utility::database_initialize( 
		$ENV{DBI_DSN}  || "dbi:Pg:dbname=botdb_elvis",
		$ENV{DBI_USER} || "alex",
		$ENV{DBI_PASS} || "" );

utility::init_communication();
utility::poe_initialize();

$daemon and daemonize();

# hold on to your butt, poe_initialize never comes back.

$poe_kernel -> run();
# think you used enough dynamite there, butch?
confess "$0: kernel returned. rapture.\n";
exit;

sub daemonize {
    fork and exit;
}
