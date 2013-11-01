#!/usr/bin/perl -w

# take an exact item name for input,
# search for it, and print the top 4 prices

use warnings;
use strict;
use Neopets::Shops::Wizard;
use Neopets::Item::Simple;
use Data::Dumper;

my $wizard = Neopets::Shops::Wizard -> new();

print "item : ";

while ( my $item_name = <> ) {
    chomp $item_name;

    my $item = Neopets::Item::Simple -> new( { name => $item_name } );

    my @items = @{ $wizard -> search( { item => $item, exact => 1 } ) };

    if ( ref $items[0] ) {
        print $items[$_] -> price() . "\n" for ( 0 .. 3 )
    } else {
        print "None Found\n";
    }

    print "item : ";
}

print "\n";
