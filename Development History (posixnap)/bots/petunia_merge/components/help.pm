#
# help.pm
# originally a direct port from elvis, changed to reflect the
# module::sub methodology. original port by andreas, original code
# by danris.
#

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
":modules" lists the loaded modules
":help modulename" prints the help text for that module, if any was defined.
HELP
}


sub public {
    my ($thischan, $thisuser, $thismsg) = @_;
    respond($thischan, $thisuser, $thismsg);
}

sub private {
    my ($thischan, $thisuser, $thismsg) = @_;
    respond($thischan, $thisuser, $thismsg)
}

sub respond {
    my ($thischan, $thisuser, $thismsg) = @_;
    if ($thismsg =~ m/^:help\s*(\S+)?/) {

		my $modulename = (defined $1) ? $1 : 'help';
	
		# append .pm to modulename if needed
		if ((not defined $utility::modules{$modulename}) &&
		    (defined $utility::modules{$modulename.".pm"})) {
		    $modulename .= '.pm';
		}
	
		if (defined $utility::modules{$modulename}) {
			{
				no strict qw{ refs };
		    	if (defined &{"$utility::modules{$modulename}::help"}) {
					&{"$utility::modules{$modulename}::help"}($thischan, $thisuser, $thismsg);
		    	} 
				else {
					utility::spew($thischan, $thisuser, "No help defined for $modulename");
				}
			}
		} else {
		    utility::spew($thischan, $thisuser, "No such module $modulename");
		}
    }
    if ($thismsg =~ m/^:modules\s*$/) { 
		utility::spew($thischan, $thisuser, "Loaded modules: ". 
				join ", ", sort keys %utility::modules);
    }
}

1;
