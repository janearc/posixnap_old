#!/usr/local/bin/perl

use warnings;
use strict;
use vars qw{ $dbh $nap $daemon %children $mynick $maintainer $debug $epoch_start };
use lib qw{ lib . };
use DBI;

use utility;

utility::database_initialize;
&utility::import_mods;
