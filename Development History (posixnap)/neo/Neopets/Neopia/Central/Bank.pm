package Neopets::Neopia::Central::Bank;

use warnings;
use strict;
use Neopets::Agent;
use Neopets::Debug;

# debug flag
our $DEBUG = 0;

=head1 NAME
Neopets::Neopia::Central::Bank - A bank module

=head1 SYNOPSIS

  # create a bank object, deposit,withdraw
  # and collect interest

  use Neopets::Agent;
  use Neopets::Neopia::Central::Bank;

  my $agent = Neopets::Agent -> new();
  my $bank = Neopets::Neopia::Central::Bank -> new({ agent => \$agent });

  $bank -> deposit( 20 );
  $bank -> withdraw( 20 );
  $bank -> collect_interest();

=head1 ABSTRACT

This module is effective for futzing with the Neopets bank
(see Neopets::Agent).

This module requires that a variable NP_HOME be set in order to function.
This should be the path to a writable directory in which this toolkit
can store information.

=head1 METHODS

The following methods are provided:

=over 4

=cut

use vars qw/@ISA $VERSION/;

@ISA = qw//;
$VERSION = 0.01;

BEGIN {
  warn "$0: please define \$NP_HOME\n" and exit unless $ENV{NP_HOME};
  warn "$0: please place a cookies.txt file in ".$ENV{NP_HOME}."\n" and exit
    unless -e $ENV{NP_HOME}."/cookies.txt";
}

use constant BANK_URL => 'http://www.neopets.com/bank.phtml';
use constant PROC_BANK_URL => 'http://www.neopets.com/process_bank.phtml';

=item $bank = Neopets::Neopia::Central::Bank->new;

This constructor takes hash arguments and
returns a bank object.  Optional arguments
are:
  agent => \$agent (takes a Neopets::Agent ref)
  debug => $debug  (true or false)


=cut

sub new {
  my $that = shift;
  my $this = ref( $that ) || $that;
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
  }, $this;
}

=item $bank -> deposit( $amount );

This method deposits $amount into the neopian
bank, where $amount is a scalar integer.

=cut

sub deposit {
  my $self = shift;
  my $np = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  $agent -> post(
    { url => PROC_BANK_URL,
      referer => BANK_URL,
      params =>
        { type => 'deposit',
          ammount => $np, },
    } );
}

=item $bank -> withdraw( $amount );

This method withdraws $amount from the neopian
bank, where $amount is a scalar integer.

=cut

sub withdraw {
  my $self = shift;
  my $np = shift;

  my $agent = ${ $self -> {objects} -> {agent} };

  $agent -> post(
    { url => PROC_BANK_URL,
      referer => BANK_URL,
      params =>
        { type => 'withdraw',
          ammount => $np },
    } );
}

=item $bank -> collect_interest();

This method collects daily interest from
the neopian bank.

=cut

sub collect_interest {
  my $self = shift;
  
  my $agent = ${ $self -> {objects} -> {agent} };

  my $page = $agent -> post(
    { url => PROC_BANK_URL,
      referer => BANK_URL,
      params =>
        { type => 'interest' },
    } );

  return ! $page =~ /You have already claimed/;
}

=item my $info = $bank -> info();

info() returns a hashref containing the following fields:

		annum_pct 
			the annual interest percentage.

		annum_amt
			the annual amount in actual neopoints.

		daily_amt
			the daily amount in neopoints.

		acct_type
			the typ of account you have.

		balance 
			your current balance.

=cut

sub info { 
	my $self = shift;
	my $agent = ${ $self -> {objects} -> {agent} };
	# we'll pretend this is a refresh.
	my $page = $agent -> get( { url => BANK_URL, referer => BANK_URL } );

	my ($acct_type, $balance, $annum_pct, $annum_amt, $daily_amt) = $page =~ m!
		<b>Account\s+Type</b>\s+:\s+<font.*?<b>(.*?)</b>.*?
		Current\s+Balance</b>\s+:\s+([0-9,NP ]+)<br>.*
		<b>([0-9.]+)%</b>\s+per\s+year.*?
		Yearly\s+Interest</b>\s+:\s+([0-9,NP ]+)<br>.*?
		will\s+gain\s+<b>([0-9,NP ]+)</b>\s+per\s+day
	!ixs;
	$annum_amt =~ y/,NP //d if $annum_amt;
	$daily_amt =~ y/,NP //d if $daily_amt;
	$balance =~ y/,NP //d if $balance;
	my $rval = { 
		annum_pct => $annum_pct,
		annum_amt => $annum_amt,
		diem_amt => $daily_amt,
		daily_amt => $daily_amt,
		acct_type => $acct_type,
		balance => $balance,
	};

	return $rval;
}

		

1;

=back

=head1 SUB CLASSES

None.

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

