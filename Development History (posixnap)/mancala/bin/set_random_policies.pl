#!/usr/bin/perl -w

use strict;
use warnings;
use Mancala::DB::Policy;

my $agent = Mancala::DB::Policy -> new();
$agent -> randomize( 3 ); # 3 => agent_id
$agent -> randomize( 4 ); # 4 => agent_id

exit;
