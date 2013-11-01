#!/usr/bin/perl

#
# grab_neopet_cookies.pl
# used to actually grab the cookies set by neopets.com
# for use in further scripts.
#
# Example:
# grab_neopet_cookies.pl
#

use warnings;
use strict;
use Neopets::Agent;
use Getopt::Long qw/:config bundling/;
use Term::ReadKey;

my $readkey = eval { require Term::ReadKey };

my ( $DEBUG, $COOKIES, $USER, $PASS );

GetOptions(
  'd'   => \$DEBUG,
  'c=s' => \$COOKIES,
  'u=s' => \$USER,
  'p=s' => \$PASS,
);

my $agent = Neopets::Agent -> new(
    { debug => $DEBUG,
      cookiefile => $COOKIES,
    } );

my ( $name, $pass );

  # get the name
if ( $USER ) {
  $name = $USER;
} else {
  print "Name : ";
  chomp ( $name = <> );
}

  # fetch the initial page
my $page =
    $agent -> get(
      { url => 'http://www.neopets.com/loginpage.phtml' } );

  # test account name
$page =
    $agent -> post(
      { url => 'http://www.neopets.com/hi.phtml',
        params =>
          { username => $name,
            destination => '/petcentral.phtml', },
        no_cache => 1,
        referer => 'http://www.neopets.com/loginpage.phtml',
      } );

  # uhoh, pet not found
if ( $page =~ 'not finding an account' )
  { print "No account found with the given username\n"; exit 1 }

  # get the pass w/o echo
if ( $PASS ) {
    $pass = $PASS;
} else {
    print "Password : ";
    ReadMode( 2 ) if $readkey;
    chomp ( $pass = <> );
    ReadMode( 0 ) if $readkey;
    print "\n";
}

  # try and login, cookies will be written automaticaly
$page =
    $agent -> post(
      { url => 'http://www.neopets.com/login.phtml',
        params =>
          { username => $name,
            password => $pass, },
        no_cache => 1,
        referer => 'http://www.neopets.com/hi.phtml',
      } );

  # whoops, didn't work
if ( $page =~ 'combination is invalid' )
  { print "Login failed, try again\n" }
elsif ( $page =~ m!http://images.neopets.com/images/neo_cop.gif! )
	{ print "sucks, your account has been frozen. frozen\@neopets.com with your username if you want to unfreeze it....\n" }

exit 0;
