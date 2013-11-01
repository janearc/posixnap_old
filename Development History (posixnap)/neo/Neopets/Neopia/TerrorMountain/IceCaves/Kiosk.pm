package Neopets::Neopia::TerrorMountain::IceCaves::Kiosk;

# XXX: i'd like to turn all these prints/warns
#      into returns (unless they are in error).
#      this will give the user more control.

use warnings;
use strict;
use Data::Dumper;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

# constructor takes agent and debug
# my $kiosk =
#   Neopets::Neopia::TerrorMountain::IceCaves::Kiosk -> new(
#     { agent => \$agent,
#       debug => $debug, } );
sub new {
  my $inner_self = shift;
  my $outer_self = ref( $inner_self ) || $inner_self;

  my ( $args ) = @_;

  my $agent = $args -> {agent};
  $DEBUG = $args -> {debug};

  unless( $agent ) # create an agent if necessary
    { $agent = \Neopets::Agent -> new( { debug => $DEBUG } )
        || die "$0: unable to create agent\n" }

  return bless {
    objects => {
      agent => $agent,
    },
  }, $outer_self;
}

# get_card()
# attempt to get a scratchcard from the kiosk wocky.
sub get_card {
	my $self = shift;

	my $base_url = 'http://www.neopets.com/winter/kiosk.phtml';

	my $get_card_url = 'http://www.neopets.com/winter/process_kiosk.phtml';
	my $response = ${ $self -> {objects} -> {agent} } -> get(
		{ url => $get_card_url,
		  referer => $base_url,
          no_cache => 1,
	} );

	if ($response) {
		if ($response =~ /give everybody else a chance/i) {
			warn "$0: get_card: oops, you need to wait two hours\n";
			return undef;
		}
		elsif ($response =~ /lucky dip/i) {
			# we got one. no "positive" message from neopets.
			return 1;
		}
	}
	else {
		warn "$0: get_card: oopsl error fetching $get_card_url\n";
		return undef;
	}

	return undef;
}

# scratch()
# scratch a card in our inventory.
sub scratch {
	my $self = shift; # $kiosk object
	
	my $base_url = 'http://www.neopets.com/winter/kiosk.phtml';

	my $agent = ${ $self -> {objects} -> {agent} };

	my $response = $agent -> get(
		{ url => $base_url,
		  referer => $base_url,
          no_cache => 1,
	} );

	if ($response) {
		# yay, we got the page.
		if ($response =~ /kiosk_lunch.gif/) {
			warn "$0: scratch: out to lunch\n";
			return undef;
		}
		elsif ($response !~ /Scratch!/) {
			warn "$0: scratch: oops! No scratch cards remain.\n";
			return undef;
		}
		
		# ----====

		# lets get the available scratchcard id's
		my @cards = $response =~ m!<option value='\d+'>[^<]+</option>!g;
		# parens necessary on shift for precedence issues
		my ($thisid) = (shift @cards) =~ /value='(\d+)'/;
		my $action = 'http://www.neopets.com/winter/kiosk2.phtml';
		my $params = "?card_id=$thisid";

		# ----====

		# ok, lets get the page.
		$response = $agent -> get(
			{ url => $action.$params,
			  referer => $base_url,
		} );

		# this could get tricky, scope is deepened
		if ($response) {
			# we could take these as an arrayref if matt complains
			my @locs = ( 1, 4, 7, 2, 3, 5 ); 
			foreach my $loc (@locs) {
				my $scr_response = $agent -> get(
					{ url => "http://www.neopets.com/winter/process_kiosk.phtml?type=scratch&loc=$loc",
					  referer => "http://www.neopets.com/winter/kiosk2.phtml",
                      no_cache => 1,
				} );
				next if ($scr_response);
				warn "$0: scratch: oops, error fetching ".
					"http://www.neopets.com/winter/process_kiosk.phtml?type=scratch&loc=$loc\n";
				return undef;
			}
			if ($response !~ /YOUR PRIZE/) {
				warn "$0: scratch: bummer, nothing won.\n";
				return 1;
			}
			else {
				my ($prize) = $response =~ m[<b>YOUR PRIZE : (.*?)</b>];
				warn "$0: scratch: won $prize. Yay.\n";
				return 1;
			}
		}
		return 1;
	}
}

1;

=head1 NAME

Neopets::Neopia::TerrorMountain::IceCaves::Kiosk

=head1 SYNOPSIS

  # create a kiosk object, get and scratch a card

  use Neopets::Agent;
  use Neopets::Neopia::TerrorMountain::IceCaves::Kiosk;

  my $agent = Neopets::Agent -> new();
  my $kiosk = Neopets::Neopia::TerrorMountain::IceCaves::Kiosk -> new(
    { agent => \$agent } );

  $kiosk -> get_card();
  $kiock -> scratch();

=head1 ABSTRACT

This is a module for use with the Scratch Card Kiosk.
It provides methods for getting and scratching scratch
cards.

=head1 METHODS

The following methods are provided:

=over 4

=item $kiosk = Neopets::Neopia::TerrorMountain::IceCaves::Kiosk -> new;

This constructor takes hash arguments and
returns a kiosk object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  debug => $debug  (true or false)

=item $kiosk -> get_card();

get_card takes no arguments, and simply fetches a card from the kiosk.
the card type of course is random. it returns true on success, and
undef on failure.

=item $kiosk -> scratch();

attempts to scratch a card in inventory. note that it does not actually
check your inventory, but rather checks the form on the kiosk page. it
returns undef on any sort of failure, and true if it scratched the card
successfully. it also will do its best to print out the prize you 
received, and warns if it didnt get anything.

=head1 SUB CLASSES

=head1 COPYRIGHT

Copyright 2002

Neopets::* are the combined works of Alex Avriette and
Matt Harrington.

Matt Harrington <narse@underdogma.net>
Alex Avriette <avriettea@speakeasy.net>

The perl5.5 vs perl < 5.5 build process is stolen with
permission from sungo and the POE team (poe.perl.org),
mostly verbatim.

I suppose we should thank the Neopets people too for
making such a thoroughly enjoyable site. Maybe one day
they will make a text interface for their site so we
wouldnt have to code an API around the LWP:: and 
HTTP:: modules, but probably not. Until then...

=head1 LICENSE

Please see the enclosed LICENSE file for licensing information.

=cut
