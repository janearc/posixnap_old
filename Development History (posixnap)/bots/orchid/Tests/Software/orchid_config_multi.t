#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

# XXX: This needs to be fixed. There should be no need
# for hardcoded paths here.
use lib '../..'; 

use Orchid::Config;

my $globalConfig = Orchid::Config -> new( 'testConfigMulti.xml' );
my @namespaces = $globalConfig -> namespaces();

ok( @namespaces == 3, " multiple configs" );
