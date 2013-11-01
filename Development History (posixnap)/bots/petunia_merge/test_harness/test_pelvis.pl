#!/usr/bin/perl

use warnings;
use strict;
use vars qw{ %modules %config };
use Carp qw{ cluck croak carp };
use Data::Dumper;
use File::Slurp;
use Broker::Config;

use utility;

# what a fucking mess. ternary kicks ass.
# check $ARGV[0], then $ENV{DBI_DSN} for our dsn; default otherwise
# check $ARGV[1], then $ENV{DBI_USER} for the user name; default otherwise
utility::database_initialize(
    defined( $ARGV[0] )
	? $ARGV[0]
	: defined( $ENV{DBI_DSN} )
	    ? $ENV{DBI_DSN} 
	    : 'dbi:Pg:dbname=botdb_elvis',
    defined( $ARGV[1] )
	? $ARGV[1]
	: defined( $ENV{DBI_USER} )
	    ? $ENV{DBI_USER}
	    : 'tyler',
    "lickme" );

tie %utility::config, "Broker::Config", ${ utility::new_dbh_handle() };

# use \loadall instead
#load_default_modules();


print "ready. begin typing -->\n";
while (chomp (my $thismsg = <>)) {
	last if $thismsg =~ /^\\quit$/o;
	my ($thischan, $thisuser) = ( $utility::config{channel},
	    "testuser" );
	test_msg( $thischan, $thisuser, $thismsg );
};

sub test_msg {
	my ($thischan, $thisuser, $thismsg) = @_;

	# commands; changed to '\' since ':' is used for module commands, no?
	if ($thismsg =~ s/^\\//o) {

	    if( $thismsg eq 'modules') {
		print Dumper \%modules;
	    }

	    elsif( $thismsg =~ /^help|\?$/ ) {
		print "UTSL:\n"
		    . "\tloadall\t\tload all modules\n"
		    . "\tunloadall\tunload all loaded modules\n"
		    . "\tmodules\t\tlist all loaded modules\n"
		    . "\tload mod ...\tload named modules\n"
		    . "\tunload mod ...\tunload named modules\n"
		    . "\tquit\t\tlaunches NORAD missiles at random targets\n"
		    . "\n";
	    }

	    elsif( $thismsg eq 'loadall' ) { load_default_modules() }

	    elsif( $thismsg eq 'unloadall' ) { unload_all_modules() }

	    elsif( my ($type, $mod) = $thismsg =~ /^((?:un|re)?load)\s+(.+)/ ) {
		foreach (my @mods = $mod =~ /(\S+)/og) {
		    $type eq 'load'
			? load_module($_)
			: $type eq 'unload'
			    ? unload_module($_)
			    : reload_module($_);
		}
	    }

	    else { print "unknown command '$thismsg'.\n" }

	}

	else {
	    print "[ $thischan/$thisuser ] [ $thismsg ]\n";
    
	    foreach my $mod (keys %modules) {
		if (defined &{"$modules{$mod}::public"}) {
		    my $sub_ref = \&{"$modules{$mod}::public"};
		    $sub_ref -> ($thischan, $thisuser, $thismsg);
		}
	    }
	}
}

sub load_default_modules {
	foreach my $module (grep { /\.pm$/ }
	    read_dir('../'.$utility::config{moddir})) {
		load_module($module);
	}
}

sub load_module {
	my ($module_name) = @_;
	
	my ($short_name) = $module_name =~ /([^.]+)\.pm$/ ? $1 : $module_name;

	if( defined $modules{$short_name} ) {
	    print "$module_name is already loaded.\n";
	}

	else {
	    my $package_name = utility::id_ize($short_name);
	    my $full_path = '../'.$utility::config{moddir}."/${short_name}.pm";

	    if( ! -f $full_path ) {
		utility::debug("could not find $module_name");
		return 0;
	    }

	    my $code = read_file($full_path);

	    eval "package $package_name; $code";
	    if ($@) {
		utility::debug("$module_name had some problems: $@");
		return 0;
	    }
	    else {
		# it was probably good
		$modules{$short_name} = $package_name;
		utility::debug("$module_name loaded without errors");
	    }
	}
}


sub unload_module {
    my ($mod) = @_;
    my $pkg = $mod;

    if (defined $pkg) {
	no strict 'refs';

	# call the unload sub
	if (defined &{"$pkg\::unload"}) {
	    my $sub_ref = \&{"$pkg\::unload"};
	    &$sub_ref();
	}

	undef %{"$pkg\::"};
	delete $main::{"$pkg\::"};

	delete $modules{$mod};
	utility::debug("$mod unloaded.");
	return 1;

    } else {
	utility::debug ("$mod was not loaded.");
	return 0; 
    }

}


sub unload_all_modules {
    foreach( keys %modules ) { unload_module( $_ ) }
}


sub reload_module {
    my( $mod ) = @_;
    unload_module( $mod );
    load_module( $mod );
}


