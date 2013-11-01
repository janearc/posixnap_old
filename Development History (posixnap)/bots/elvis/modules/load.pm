our $help = '
":load module" loads a module 
":unload module" unloads a module';

sub public {
    my ($chan, $nick, $msg) = @_;
    &respond($chan, $nick, $msg);
}


sub private {
    my ($nick, $msg) = @_;
    &respond('private', $nick, $msg);
}


sub respond {
    my ($chan, $nick, $msg) = @_;
    my $mainresponse = ($chan eq 'private')?$nick:'public';

    if ($msg =~ m/^\s*:load (\S+)\s*$/) {
	my $modulename = $1;
	# append .pm to modulename if needed
	if (not defined $modules{$modulename} &&
	    defined $modules{"$modulename.pm"}) {
	    $modulename .= '.pm';
	}


	&utility::import_mods();

	if (not main::load_module($1)) {
	    &utility::spew($mainresponse, "$1 had some problems...");
	    &utility::private_spew($nick, "*** problems loading $1...\n$@");
	} else {
	    &utility::spew($mainresponse, "$1 loaded without errors.");
	}
    }

    if ($msg =~ m/^\s*:unload (\S+)\s*/) {
	if (main::unload_module($1)) {
	    utility::spew($mainresponse, "$1 unloaded.");
	} else {
	    utility::spew($mainresponse, "$1 was not loaded.");
	}
    }
}

1;
