package utility;

use warnings;
use strict qw{ vars subs };
use Carp qw{ cluck croak carp confess };
use Data::Dumper;

our ($dbhandle, $db_dsn, $db_user, $db_pass, %modules, %config, $kernel);

use DBI;
use File::Slurp;

use POE;
use POE::Component::IRC;
use POE::Kernel;

use Broker::Config;
use Broker::EvilDBH;

use utility::control;
use utility::communication;

sub is_maintainer {
    my ($nick) = @_;
    my $ret = 0;
    return $ret if $nick =~ /[^\w]/;
    my $sth = $dbhandle->prepare("SELECT nick FROM maintainers WHERE nick = ?");
    $sth->execute($nick);
    my $res = $sth->fetchrow_array;
    if( defined $res ) { $ret = 1 };
    $sth->finish;
    return $ret;
}

sub database_initialize {
	($db_dsn, $db_user, $db_pass)  = @_;
	my @dbi_params = (
		$db_dsn,
		$db_user,
		$db_pass,
	);

	tie $dbhandle, 'Broker::EvilDBH', @dbi_params;
	# Bummer, Broker::Config uses static dbh's (afaict). So for EvilDBH
	# to work as intended, we need to use /EvilDBH's/ config, which will
	# be changed as needed.
	*config = \%Broker::EvilDBH::config;

	# make sure we have the proper dsn information
	$config{epoch_start} = time();
	$config{dsn} = $db_dsn;
	$config{db_user} = $db_user;
	$config{db_pass} = $db_pass;
	debug( "initial \%config DSN settings added\n" );

	1;
}

# we stole this from jason. import all the communication functions
# so that users can refer to them as part of utility::
sub init_communication {
	# EVIL, i tell you! eeeeeeevil!
	foreach my $method ( keys %{ "utility::communication::" } ) {
		{ 
			no strict; # you heard me, buddy
			no warnings;
			if( defined \&{"utility::communication::$method"} and not defined *{__PACKAGE__."::$method"}) {
				debug( "trapped $method, creating sub" ); # for async
				push @overridden_methods, $method;
				eval 
					qq# sub $method { #.					# interpolated
					q#&utility::communication::#.	# not
					qq#$method( #.								# interpolated
					q#@_ ); } #;									# not
				print $@ if $@;
			}
		}
	}
}

sub load_default_modules {
  foreach my $module (grep { /\.pm$/ } read_dir($config{moddir})) {
    load_module($module);
  }
}

sub new_dbh_handle {
    my $ref = tied $dbhandle;
    return \$ref;
}

# Escape everything into valid perl identifiers
# this is stolen from mod_perl's Apache::Registry
sub id_ize {
    my ($script_name) = @_;
    $script_name =~ s/([^A-Za-z0-9_\/])/sprintf("_%2x",unpack("C",$1))/eg;
    
    # second pass cares for slashes and words starting with a digit
    $script_name =~ s{
	(/+)       # directory
	    (\d?)      # package's first character
	}[
	  "::" . (length $2 ? sprintf("_%2x",unpack("C",$2)) : "")
	  ]egx;
    $script_name;
}

sub load_module {
	my ($module_name) = @_;
	
	my ($short_name) = $module_name =~ /([^.]+)\.pm/ ? $1 : $module_name;
	
	my $package_name = utility::id_ize($short_name);

	my $path = $config{moddir}.'/'.$short_name.'.pm';
	if( not -e $path ) {
	    utility::debug( "$path not found or not a regular file." );
	    return 0;
	}

	my $code = read_file($path);

	eval "package $package_name; $code";
	if ($@) {
		utility::debug("$module_name had some problems: $@");
		return 0;
	}
	else {
		# it was probably good
		$modules{$short_name} = $package_name;
		utility::debug("$module_name loaded without errors");
		if (defined *{"$modules{$short_name}\::init"}) {
			my $sub_ref = \&{"$modules{$short_name}\::init"};
			# this is the new init() style
			$sub_ref -> ( $main::poe_kernel, [ $db_dsn, $db_user, $db_pass ], \%config);
		}
	}

	return 1;
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

	# JZ: Fear the reaper. But for the record, I think this is cool:
	#   for my $thing (map { "$pkg\::$_" } keys %{"$pkg\::"}) {
	#	undef ${"$thing"};
	#	...
	# JZ: Here's the new version.
	undef %{"$package_name\::"};
	delete $main::{"$package_name\::"};
			
	delete $modules{$mod};
	debug("$mod unloaded.");
	return 1;
    } else {
	debug ("$mod was not loaded.");
	return 0;
    }
    
}

sub _start {
  my ($thiskernel) = $_[KERNEL];

  $thiskernel->alias_set( $config{nick} );
  $thiskernel->post( $config{nick}, 'register', 'all' );
  $thiskernel->post( $config{nick}, 'connect', { 
		Debug    => 1,
		Nick     => $config{nick},
		Server   => $ARGV[0] || $config{server},
		Port     => $ARGV[1] || $config{port},
		Username => $config{username},
		Ircname  => $config{ircname},
	});

	$utility::communication::kernel ||= $_[KERNEL];

	1;
}

sub _stop {
  my ($thiskernel) = $_[KERNEL];

  debug( "Control session stopped." );
  $thiskernel->call( $config{nick}, 'quit', 'http://www.tubgirl.com/' );
}

sub irc_disconnected {
  my ($server) = $_[ARG0];
  debug( "Lost connection to server $server." );
	if ($server eq $config{alternate_server}) {
		debug( "Attempting to reconnect to primary server." );
		# XXX....
	}
}

sub irc_error {
  my $err = $_[ARG0];
  debug( "Server error occurred! $err" );
}

sub irc_socketerr {
  my $err = $_[ARG0];
  debug( "Couldn't connect to server: $err" );
}

sub irc_001 {
  my ($thiskernel) = $_[KERNEL];

  $thiskernel->post( $config{nick}, 'mode', $config{nick}, '-i+w' );

	load_default_modules();

}

sub import_modules {
    my $moddir = $config{moddir};
    opendir MODULES, $moddir;
    
    #my $dbh = ${ new_dbh_handle() };
    my $defaults = $dbhandle->selectcol_arrayref
	("SELECT name FROM modules WHERE \"default\" = 't'");

    $dbhandle->do('DELETE FROM modules', undef);

    my $saved_separator = $/;
    # slurp entire files.
    undef $/;
    
    # for each quote 
    while (my $modname = readdir MODULES) {
	 if (-f "$moddir/$modname" 
	     && -r "$moddir/$modname"
	     && $modname !~ /^\#/) {
	     print STDERR "importing $modname... \n";
	     open MOD, "$moddir/$modname";
	     my $code = <MOD> ;
	     close MOD;
	     $dbhandle->do('INSERT INTO modules (name, "default", code) '
		      . 'VALUES (?, ?, ?)', 
		      undef, 
		      $modname, 
		      (grep { $_ eq $modname } @{$defaults})?'t':'f',
		      $code);
	}
    }
    $/ = $saved_separator;

}

sub debug ($) {

	my ($package, $line, $subroutine) = ( caller(1) )[0, 2, 3];
	my $prefix = "$0: $package: $subroutine"."[$line]: ";

	warn $prefix.$_[0].$/;
}

sub poe_initialize {
	POE::Component::IRC -> new( $config{nick} )
		or confess "Can't instantiate new IRC component.\n";
	POE::Session -> new( 
		'utility' => [ qw{
			_start	_stop	irc_001	irc_disconnected
			irc_socketerr	irc_error	
		} ],
		'utility::control' => [ qw{
			irc_public
			irc_msg
			irc_kick
			irc_join
			irc_part
		} ],
	);

	debug( "we are strapped, somebody come boot me..." );
}

1;
