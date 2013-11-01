#!/usr/bin/perl

$|++;

package neo::tests::test;

use strict;
use warnings;

use Test::Harness qw/&runtests $verbose/;
$verbose = $ENV{TEST_VERBOSE};

my $input;

opendir( T, 'tests' ) || die "cannot find test script dir: $!";
my @scripts = map { /^[0-9][0-9]/ ? "tests/$_" : ( ) } readdir(T);

unless ( $ENV{NP_HOME} ) {

    print << "NP_HOME";

===============================================================

These modules require the shell variable \$NP_HOME be set and
  it is not.  This is where this module set will store its data.
  Where would you like \$NP_HOME?

NP_HOME

    print "[$ENV{HOME}/.neopets/]: ";

    $input = <>;
    chomp $input;
    $input = $ENV{HOME}.'/.neopets/' unless $input;
    unless ( -f $input )
        { mkdir ( $input ) }

    $ENV{NP_HOME} = $input;
}

print << "EXTRA";

================================================================

Some modules are optional and thus are not tested for by default.

EXTRA

print "Would you like to test the functions that require\n";
print " these optional modules? [y/N]: ";

$input = <>;

if ( $input =~ /y/i ) {
    $ENV{EXTRA} = 1;
}

print << "AGENT";

================================================================

Some of these tests require a functioning internet connection
  to function, otherwise they will take much time before failing.

AGENT

print "Do you want to run these tests? [y/N]: ";

$input = <>;

if ( $input =~ /y/i ) {
    $ENV{AGENT} = 1;
}

if ( $ENV{AGENT} ) {
    print << "ACCOUNT";

================================================================

I can also perform tests that only work when you have a valid
  Neopets account, otherwise these tests will be skipped.

ACCOUNT

    print "Would you like to perform these tests? [y/N]: ";

    $input = <>;

    if ( $input =~ /y/i ) {
        # uhoh, the user wants to login, better get everything set
        require Neopets::Agent;

        my $agent = Neopets::Agent -> new();

        # collect user info
        print "You must now login\n";
        print " Username: ";
        chomp( my $user = <> );
        print " Password: ";
        chomp( my $pass = <> );

        if ( $user and $pass ) {
            print "logging in...";
            my $page = $agent -> get({ url => "http://www.neopets.com/login.phtml?destination=/petcentral.phtml&username=$user&password=$pass" });

            if ( $page =~ /combination is invalid/ ) {
                print "The username/password pair did not work, skipping tests\n";
            } else {
                print "Logged in\n";
                $ENV{ACCOUNT} = 1;
            }
        } else {
            print "Incorrect information recieved, skipping tests\n";
        }
    }
}

print "================================================================\n\n";
print "\t\$NP_HOME:\t$ENV{NP_HOME}\n";
print "\tOptional Tests:\t".($ENV{EXTRA} ? 'YES' : 'NO')."\n";
print "\tAgent Tests:\t".($ENV{AGENT} ? 'YES' : 'NO')."\n";
print "\tAccount Tests:\t".($ENV{ACCOUNT} ? 'YES' : 'NO')."\n";
print "\n";
print "================================================================\n\n";

my $allok = runtests( @scripts );

if ( $allok )
    { print "\n *** All Tests Successful ***\n\n" and exit 0 }
else
    { print "\n XXX Some Tests Failed XXX\n\n" and exit 1 }
