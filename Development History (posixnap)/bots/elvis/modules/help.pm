our $help ='
":modules" lists the loaded modules
 
":help modulename" prints the help text for that module, if any was defined.';

sub public {
    my ($channel, $nick, $msg) = @_;
    &respond("public", $msg);
}

sub private {
    my ($nick, $msg) = @_;
    &respond($nick, $msg)
}

sub respond {
    my ($nick, $msg) = @_;
    if ($msg =~ m/^\s*:help\s+(\S+)/) {
	my $modulename = $1;

	# append .pm to modulename if needed
	if ((not defined $modules{$modulename}) &&
	    (defined $modules{"$modulename.pm"})) {
	    $modulename .= '.pm';
	}

	if (defined $modules{$modulename}) {
	    if (defined ${"$modules{$modulename}::help"}) {
		&utility::spew($nick, ${"$modules{$modulename}::help"});
	    } else {
		&utility::spew($nick, "No help defined for $modulename");
	    }
	} else {
	    &utility::spew($nick, "No such module $modulename");
	}
    }
    if ($msg =~ m/^\s*:modules\s*$/) { 
	&utility::spew($nick, "Loaded modules: ". join ", ", sort keys %modules);
    }

}

1;
