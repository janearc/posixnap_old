package CJP::Connect;

use warnings;
use strict;

use DBI;
our $dbh = DBI -> connect( "dbi:Pg:dbname=timetracker", "timetracker", "" )
	or die DBI -> errstr();

sub new {
	my $self = shift;
	my @args = @_;
	
	return bless { dbh => \$dbh }, $self;

}

