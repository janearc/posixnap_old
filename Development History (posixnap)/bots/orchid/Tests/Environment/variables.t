#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

our $ORCHID_HOME = $ENV{ORCHID_HOME};
our $PERL = $ENV{PERL};

# check to see if our environment is marginally happy
ok( defined $ORCHID_HOME, " ORCHID_HOME envrionment variable" );
ok( defined $PERL, " PERL variable" );
