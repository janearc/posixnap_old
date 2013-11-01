package utility;

# XXX: need to improve these credits
# portions of this code was taken from the petunia_merge
# poe irc bot project. this is credit Alex Avriette and
# Jason Zdan

use warnings;
use strict qw{ vars subs };
use Carp qw{ cluck croak carp confess };

our (%modules, %config);

use File::Slurp;

# load all modules in $config{moddir}

sub load_default_modules {
  foreach my $module (grep { /^[^-].*\.pm$/ } read_dir($config{moddir})) {
    load_module($module);
  }
}

# unload loaded modules that are not in config{moddir}
# unload loaded modules that are not current (checks mtime)

sub unload_old_modules {
    my @modules = (grep { /^[^-].*\.pm$/ } read_dir($config{moddir}));
    foreach my $loaded ( keys %modules ) {
        my $found;

        foreach my $module ( @modules ) {
            my @stat = stat $config{moddir}.'/'.$module;
            ( $module ) = $module =~ m/(.*)\.pm/;

            if ( ( $module eq $loaded )
                    and ( $modules{$module} -> {vers} >= $stat[9] ) )
                { $found = 1 }
        }

        unload_module ( $loaded )
            unless ( $found );
    }
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
    if( not -f $path ) {
        utility::debug( "$path not found or not a regular file." );
        return 0;
    }

    my $code = read_file($path);
    my @stat = stat $path;

    # if a module already exists and is current, don't reload
    if ( not($modules{$short_name} )
                or ($modules{$short_name} -> {vers} < $stat[9] ) ) {

        debug("creating $package_name");
        eval "package $package_name; $code";
        if ($@) {
            utility::debug("$module_name had some problems: $@");
            return 0;
        }
        else {
            # it was probably good
            $modules{$short_name} -> {code} = $package_name;
            $modules{$short_name} -> {vers} = $stat[9];
            utility::debug("$module_name loaded without errors");

            # call module::init() if it exists
            if ( defined &{ $short_name.'::init' } )
                { &{ 'main::'.$short_name.'::init' } }
        }
    }

    return 1;
}

sub unload_module {
    my ($mod) = @_;
    my $package_name = $modules{$mod} -> {code};
    if (defined $package_name) {

        # call the unload sub
        if (defined &{$modules{$mod}->{code}."::unload"}) {
            my $sub_ref = \&{$modules{$mod}->{code}."::unload"};
            &$sub_ref();
        }

        # JZ: Fear the reaper. But for the record, I think this is cool:
        #   for my $thing (map { "$pkg\::$_" } keys %{"$pkg\::"}) {
        #       undef ${"$thing"};
        #       ...
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

sub debug ($) {
    if ( $config{debug} ) {
        my ($package, $line, $subroutine) = ( caller(1) )[0, 2, 3];
        my $prefix = "$0: $package: $subroutine"."[$line]: ";

        warn $prefix.$_[0].$/;
    }
}

1;
