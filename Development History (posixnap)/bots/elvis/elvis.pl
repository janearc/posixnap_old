#!/usr/local/bin/perl

use warnings;
use strict;
no strict "refs";
#use vars qw{ $dbh $nap $daemon %modules $mynick $debug $epoch_start %config };
our ( $dbh, $nap, $daemon, %modules, $mynick, $debug, $epoch_start, %config );
use lib qw{ lib . };

use Carp qw{ cluck croak carp };
use Data::Dumper;
#require Devel::Symdump;

use DBI;

use MP3::Napster;
use constant MSG_SERVER_NOSUCH => 404;
use constant MSG_SERVER_PUBLIC => 403;
use constant MSG_CLIENT_EMOTE => 824;
use constant MSG_CLIENT_PRIVMSG => 205;

use utility;

# Broker::Config is overkill here, but hell, I had it handy.
use Broker::Config;

$daemon = 0;
$debug = 1;
$epoch_start = time();

$daemon and &daemonize;
&utility::database_initialize();
tie %config, "Broker::Config", $dbh;
&load_default_modules;
&napster_initialize();
&callbacks_initialize();
$nap -> run();
exit;

sub daemonize {
    fork and exit;
}

sub napster_initialize {
    $mynick = $config{nick};
    
    $nap = MP3::Napster -> new( "$config{server}:$config{port}" )
	or croak "could not instantiate \$nap object!\n".$nap -> error();
    $nap -> login($mynick, $config{password})
	or croak "could not log in to server $config{server} [". $nap -> error() ."]\n";
    
    $nap -> join_channel($config{channel});
    1;
}

sub public_messages {
    my $nap_object = shift;
    my @args = @{ shift() };
    my ($ec, $message) = @args;
    return unless my ($channel, $nick, $packet) = $message =~ /^(\S+) (\S+) (.*)/;
    return unless $nick !~ /^$mynick$/;
    if (!$daemon and $debug) {
	print "[ $ec ] [ $channel/$nick ] [ $packet ]\n";
    }
    
    for my $mod (keys %modules) {
	if (defined &{"$modules{$mod}::public"}) {
	    my $sub_ref = \&{"$modules{$mod}::public"};
	    &$sub_ref($channel, $nick, $packet);
	}
    }
}

sub private_messages {
    my $nap_object = shift;
    my @args = @{ shift() };
    my ($ec, $message) = @args;
    return unless my ($nick, $packet) = $message =~ /^(\S+) (.*)/;
    return unless $nick !~ /^$mynick$/;
    if (!$daemon and $debug) {
	print "[ $ec ] [ private/$nick ] [ $packet ]\n";
    }
    
    for my $mod (keys %modules) {
	if (defined &{"$modules{$mod}::private"}) {
	    my $sub_ref = \&{"$modules{$mod}::private"};
	    &$sub_ref($nick, $packet);
	}
    }
}

sub emote_messages {
    my $nap_object = shift;
    my @args = @{ shift() };
    my ($ec, $message) = @args;
    return unless my ($channel, $nick, $packet) = $message =~ /^(\S+) (\S+) (.*)/;
    return unless $nick !~ /^$mynick$/;
    if (!$daemon and $debug) {
	print STDERR "[ $ec ] [ $channel/$nick ] emotes [ $packet ]\n";
    }
    
    for my $mod (keys %modules) {
	if (defined &{"$modules{$mod}::emote"}) {
	    my $sub_ref = \&{"$modules{$mod}::emote"};
	    &$sub_ref($channel, $nick, $packet);
	}
    }
}

sub server_error_messages {
	1;
}

sub callbacks_initialize {
    $nap -> callback (MSG_SERVER_NOSUCH, 
		      sub { server_error_messages($_[0], [@_[1..$#_]]) });
    $nap -> callback (MSG_SERVER_PUBLIC, 
		      sub { public_messages($_[0], [@_[1..$#_]]) });
    $nap -> callback (MSG_CLIENT_EMOTE, 
		      sub { emote_messages($_[0], [@_[1..$#_]]) });
    $nap -> callback (MSG_CLIENT_PRIVMSG, 
		      sub { private_messages($_[0], [@_[1..$#_]]) });
}

sub load_default_modules {
    my $res = $dbh->selectcol_arrayref('SELECT name FROM modules '
				       .'WHERE "default" = TRUE');
    for my $m (@$res) {
	&load_module($m);
    }
    
}

sub load_module {
    my ($module_name) = @_;
    $module_name =~ s/\.pm$//;
    my $res = $dbh->selectcol_arrayref('SELECT code FROM modules '
				       .'WHERE name = ? '
				       .'OR name = ? ',
				       undef,
				       $module_name,
				       "$module_name.pm");
    $res = $$res[0];
    if (not defined $res) {
	$@ = "failed to find module $module_name\n";
	&debug($@); 
	return 0;
    }
    
    my $package_name = utility::id_ize($module_name);
    my $warning = "";
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    eval "package $package_name; $res";
    if ($@) {
	$@ = "$warning\n$@";
	&debug("$module_name had some problems: $@");
	return 0;
    }
    else {
	# it was probably good
	$modules{$module_name} = $package_name;
	&debug("$module_name loaded without errors");
    }
}


sub unload_module {
    my ($mod) = @_;
    my $package_name = $modules{$mod};
    if (defined $package_name) {

	# call the unload sub
	if (defined &{"$modules{$mod}::unload"}) {
	    my $sub_ref = \&{"$modules{$mod}::unload"};
	    &$sub_ref();
	}

	# undef the subs/vars
	for my $thing (keys %{"$package_name\::"}) {
	    undef &{"$package_name::$thing"};
	    undef ${"$package_name::$thing"};
	    undef @{"$package_name::$thing"};
	}
	delete $modules{$mod};
	debug("$mod unloaded.");
	return 1;
    } else {
	debug ("$mod was not loaded.");
	return 0;
    }
    
}

sub debug {
    if ($debug) { print STDERR @_, "\n"; }
}
