our $help = '
:debug turns on the debugging flag.
:nodebug turns off the debugging flag.
:diagnostic does something ad-hoc
Loading the module turns on the flag.
Unloading the module turns it off.
';

$debug = 1;

sub unload {
    $debug = 0;
}

sub private {
    my ($nick, $msg) = @_;
    if ($msg =~ m/^\s*:debug\s*$/) {
	$debug = 1;
    }
    if ($msg =~ m/^\s*:nodebug\s*$/) {
	$debug = 0;
    }
    if ($msg =~ /^\s*:diagnostic\s*/) {
	&diagnostic($nick, $msg);
    }
}

sub public {
    my ($channel, $nick, $msg) = @_;
    &private('public', $msg);
}

sub diagnostic {
    my ($nick, $msg) = @_;

    &utility::spew($nick, Data::Dumper->Dump([\%modules]));
}
