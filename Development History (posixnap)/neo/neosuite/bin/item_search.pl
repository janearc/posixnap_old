#!/usr/bin/perl -w

use constant DEBUG => 0;

# this will ask for an item
# via stdin and return the
# first store owner and price

$|++;

# hack the cookies
chomp( $ENV{NP_HOME} = `pwd` );

use strict;
use warnings;

# required modules
use Neopets::Agent;
use Neopets::Item::Simple;
use Neopets::Shops::Wizard;

# setup objects
my $agent = Neopets::Agent -> new(
    { cookie_file => 'cookies.txt', debug => DEBUG } );

my $wizard = Neopets::Shops::Wizard -> new(
    { agent => \$agent, debug => DEBUG } );

print "item name : ";
while ( <> ) {
    my $item_name;
    if ( chomp( $item_name = $_ ) ) {
        my $item = Neopets::Item::Simple -> new(
            { name => $item_name } );
        if ( $item = _find( $item, 1 ) ) {
            print "Found ", $item -> {name}, " at ", $item -> {owner},
                    " for ", $item -> {price}, "\n";
        } else {
            print "item not found\n";
        }
    }
    print "item name : ";
}

print "\n";

sub _find {
    my $item = shift;
    my $exact = shift;

    # search
    my $shops = $wizard -> search(
        { item => $item,
          exact => $exact } );

    # if something is found, return it
    if ( ref $shops -> [0] )
        { return $shops -> [0] }

    # if not found with exact, repeat without
    if ( $exact ) 
        { return _find( $item, 0 ) }

    # return nothing found
    return;
}

