#!/usr/bin/perl -w

#
# wizard.pl
# grok the neopets wizard and buy the specified item where it is found
# at below the specified price
#
# Reads input from stdin when using the -s tag.
# Example imput:
#  Orn Codestone:3999:2
#  Bri Codestone:4099:3
#
# this will retrieve 3 bri codestones and 2 orn codestones at
# the given price, in no particular order
#
# Optionally, can read input from a file, using the -f file
# tag, where file is of the above format
# Example:
# ./wizard.pl -f items.txt
# will search . and $NP_HOME/ for file
#
# if no arguments are given, assumes -s (stdin)
#
# pass -q for minimal output
# pass -u for summary information
# pass it the -d flag for debug
#
# additionally the wizard will read xml files
# Example input:
#
# <wizard-search-items>
#   <xml>1</xml>
#     <item>
#         <name>Orn Codestone</name>
#         <price>4049</price>
#         <quantity>2</quantity>
#  </item>
# </wizard-search-items>
#
# xml input file must have .xml suffix and contain:
#    <xml>1</xml>
# somewhere within the first layer
#


$|++;
use constant MAX_TRIES => '10';
use constant SHOP_URL => 'http://www.neopets.com/browseshop.phtml?owner=';
use constant ITEM => 0;
use constant PRICE => 1;
use constant COUNT => 2;

use strict;
use warnings;
use Getopt::Long qw/:config bundling/;
use Data::Dumper;
use Neopets::Agent;
use Neopets::Config;
use Neopets::Shops;
use Neopets::Shops::Wizard;
use Neopets::Item::Simple;

my ( $DEBUG, $IS_FILE, $IS_STDIN, $MAX_TRIES, $SUMMARY, $QUIET, $COOKIES );

GetOptions(
  'd'   => \$DEBUG,
  'c=s' => \$COOKIES,
  'f=s' => \$IS_FILE,
  's'   => \$IS_STDIN,
  't=i' => \$MAX_TRIES,
  'u'   => \$SUMMARY,
  'q'   => \$QUIET,
);

  # set the max tries if necessary
$MAX_TRIES = MAX_TRIES unless ( $MAX_TRIES );

my $agent = Neopets::Agent -> new(
  { debug => $DEBUG,
    cookiefile => $COOKIES,
  } );
my $config = Neopets::Config -> new();
my $shop = Neopets::Shops -> new(
  { agent => \$agent,
    debug => $DEBUG
  } );
my $wizard = Neopets::Shops::Wizard -> new(
  { agent => \$agent,
    debug => $DEBUG, } );

# get the name of the user, so as not to buy from their own store
my ( $name ) = $agent -> username();

  # get the item list
my $items = $config -> read_config( { STDIN => $IS_STDIN, file => $IS_FILE } );

  # get the items
my %bought = ( );


if ( $items -> {xml} or ( ($items -> {version}) and ( $items -> {version} >= 2 ) ) ) { # for xml stuff
  my ( $items ) = $items -> {item};
  foreach my $name ( keys %{ $items } ) {
    $bought{ $name } = buy( $name, $items -> {$name} -> {price}, $items -> {$name} -> {quantity} );
  }
} else { # for : delimited stuff
  foreach my $name ( keys %{ $items } ) {
    # this is the way this line should look, but instead it misparses
    # the constants and doesn't work.  the second line just hardcodes
    # these constants in
    #$bought{ $name } = buy( $name, $items -> {$name} -> {PRICE}, $items -> {$name} -> {COUNT});
    $bought{ $name } = buy( $name, $items -> {$name} -> {1}, $items -> {$name} -> {2});
  }
}

if ( ( $SUMMARY ) or (! $QUIET ) ) {
  print "\n\tSUMMARY:\n";
  foreach my $item ( keys %bought ) {
    print " - Got ".$bought{ $item }." x $item\n";
  }
}


exit 0;

# buy( $item, $price, $count )
# XXX: also check to see if we have enough cash.
sub buy {
  my ( $item, $wanted_price, $count ) = @_;
  my $tries; # record the number of tries;
  my $bought = 0;

  print "\nStarting search for $count x $item at <= $wanted_price\n" unless ( $QUIET );

  while ( $count - $bought ) {

    my $item_to_buy;

    while (! $item_to_buy ) {
      if ( $tries++ > $MAX_TRIES ) { # end if MAX_TRIES
        $DEBUG and print "Exceded the number of tries, aborting item \'$item\'\n";
	return $bought;
      }

          # get a list of items offered by the wiz search
      my @found_items = @{ $wizard -> search( {
                                                item => $item,
                                                max_price => $wanted_price,
                                                exact => 1,
                                            } ) };

          # if this doesn't exist, we are in trouble
      if ( @found_items ) {
            # catch and die if the store is busy
        if ( $found_items[0] eq 'BUSY' )
          { die "$0: buy: too many requests, ease off for \'$found_items[1]\' minutes\n" }
        elsif ( $found_items[0] eq 'NONE FOUND' )
	  { warn "None found\n" and @found_items = qw// }

          # check again incase 'NONE FOUND'
        if ( @found_items ) {
              # set $item_to_buy
	      # if the first store is owned by the user, get the second
	  if ( $found_items[0] -> owner() eq $name )
	    { $item_to_buy = $found_items[1] }
          else
	    { $item_to_buy = $found_items[0] }
        }

      } else { # if ( @found_items ), no shops found
         $DEBUG and print "No shops found\n";
      }
    }

    print " - ".$item_to_buy->name()." found for ".$item_to_buy->price().". Getting listing..." unless ( $QUIET );
    my $listing = $shop -> listing( $item_to_buy->owner() );
    print " done\n" unless ( $QUIET );

        # get the location and set it in one step
	# if this fails, the item was sold already
        # this will fail if the item text has br's and such in it. eg:
	# Orn&nbsp; Codestone
	# XXX: there has to be a more robust way to search.
    if ( $item_to_buy -> location(
             $listing -> { $item_to_buy->name() } ) ) {

          # buy it, incriment $bought if successful
      print "Getting Item (",$item_to_buy->name().")..." unless ( $QUIET );

      $shop -> buy( $item_to_buy )
          and $bought++;
      
    } else { # $link == undef
      print "No more...\n" unless ( $QUIET );
    }
  }

  return $bought;
}
