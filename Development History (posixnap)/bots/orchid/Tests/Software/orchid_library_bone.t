#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

# XXX: This needs to be fixed. There should be no need
# for hardcoded paths here.
use lib '../..'; 

use Orchid::Library::Bone;

my ($boneEasy, $boning);
ok( $boneEasy = Orchid::Library::Bone -> new(), " instantiating object" );
ok( $boning = $boneEasy -> bone(), " bone: $boning" );
