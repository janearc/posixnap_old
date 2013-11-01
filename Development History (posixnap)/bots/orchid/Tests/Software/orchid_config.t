#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

# XXX: This needs to be fixed. There should be no need
# for hardcoded paths here.
use lib '../..'; 

use Orchid::Config;

ok( my $globalConfig = Orchid::Config -> new( 'testConfig.xml' ), " new()" );
ok( my $blather = $globalConfig -> splort(), " splort()" );
