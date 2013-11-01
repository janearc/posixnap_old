#!/home/alex/bin/perl -l

# $Id: project_namer.pl,v 1.4 2004-03-13 03:09:03 alex Exp $ 
# based upon something on the intarneb mister sungo showed me.
# i don't know who wrote it. but i wrote this. nyah.

use warnings;
use strict;
use List::Util qw/ shuffle /;
use CGI qw/ :standard /;

my @ones = shuffle qw{
	fierce quivering slippery sharp poignant invisible holy
	abominable frozen molten giant inverted juxtaposed divine
	furious impenetrable quixotic unintelligible mysterious
	spiteful deep islamic buddhist sour bitter french surprise
	negligible ancient mnemonic frickin' homeopathic infinite
	subversive subconscious hyper booming super midnight high-noon
	pre-dawn quickening quiet thundering absent opaque translucent
	mighty fabulous sinister encrypted smelly sweeping icelandic
	finnish negative flying posthumous shaved microwave radiant
	fiery omnipotent elven unbelievable fictitious rotating hostile
	poisonous venomous deadly fearsome pointy gothic perilous
	travelling fragmented volcanic saturated aging proud forbidden
	frightened tiny oriental falling flying plaid broken shattered
	undead hollow purple green incandescent glittering glistening
	homophobic agency lunar obsidian hypersonic misplaced homing
};

my @twos = shuffle qw{
	penguin rhino slipper canyon mountain burrito donkey fox
	elephant wind storm ocean war medallion pretzel window service
	charity death quagmire entrapment thunder leader meadow desert
	pie continent hurricane carpet shoe salesman jihad salmon
	polarbear alligator battleship trout hobbit salad spider widow
	monk crusade carrot snifter castle engine palace impulse
	redemption squirrel taco journey cannon train victory chalice
	libido papyrus phallus donut schoolbus carrion mongoose
	dormouse wombat cadaver tunnel stairway force wave soldier
	knife mystery euphemism quiche intelligence rocks music
	transmission receiver angle trajectory warrior
};

print 
	header(), 
	start_html( -title => 'Your new Project Name' ), 
	h1( join $", map { ucfirst $_ } shift @ones, shift @twos ),
	end_html;
