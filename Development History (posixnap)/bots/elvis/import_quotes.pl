#!/usr/local/bin/perl

use warnings;
use strict;
use vars qw{ $dbh $nap $daemon %children $mynick $maintainer $debug $epoch_start };
use lib qw{ lib . };
use DBI;

use utility;

sub import_data {
    open QUOTES, "quotes.txt";

    my $saved_separator = $/;
    $/ = "\n\n";
    
    $dbh->do('DELETE from elvisquotes', undef);
    
    # for each quote 
    while (my $quote = <QUOTES>) {
	$dbh->do('INSERT INTO elvisquotes (quote) values (?)', undef, $quote);
    }
}

utility::database_initialize;
&import_data;
