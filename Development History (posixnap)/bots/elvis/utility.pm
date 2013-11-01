use warnings;
use strict;
use lib qw{ lib . };
use DBI;

use utility;
our ($dbh, $nap, $daemon, %children, $mynick, $maintainer, $debug, $epoch_start) ;

package utility;
use Carp qw{ cluck croak carp };

sub database_initialize {
        my $DBD = "Pg";
        my $dbname = "botdb";
        my $dbhost = "10.0.0.2";
        my $dbuser = "magnus";
        my $dbpass = "foo";
        my @dbi_params = (
                #"dbi:".$DBD.":dbname=".$dbname,
                "dbi:".$DBD.":dbname=".$dbname.";host=".$dbhost,
                $dbuser,
                $dbpass,
        );
        $dbh = DBI -> connect(@dbi_params)
                or croak "".DBI -> errstr."\n"; # this is kind of sucky, blame perl.
        1;
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


sub public_spew {
    my ($msg) = @_;
    for my $l (split /\n/, $msg) {
	$nap->public_message($l);
    }
}

sub private_spew {
    my ($nic, $msg) = @_;
    for my $l (split /\n/, $msg) {
	$nap->private_message($nic, $l);
    }
}

sub spew {
    my ($nic, $msg) = @_;
    if ($nic eq "public") {
	for my $l (split /\n/, $msg) {
	    $nap->public_message($l);
	}
    } else {
	for my $l (split /\n/, $msg) {
	    $nap->private_message($nic, $l);
	}
    }	
}
    
my $moddir = './modules';

sub import_mods {
    opendir MODULES, $moddir;
    
    my $defaults = $dbh->selectcol_arrayref("SELECT name FROM modules WHERE \"default\" = 't'");

    $dbh->do('DELETE FROM modules', undef);

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
	     $dbh->do('INSERT INTO modules (name, "default", code) VALUES (?, ?, ?)', 
		      undef, 
		      $modname, 
		      (grep { $_ eq $modname } @{$defaults})?'t':'f',
		      $code);
	}
    }
    $/ = $saved_separator;

}


1;
