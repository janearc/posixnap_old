package CJP::Task;

use warnings;
use strict;

sub new { 
	my $self = shift;
	my @args = @_;

	return bless { 
		client => '',
		taskid => '',
		bee => '',
		email => '',
		taskname => '',
	}, $self;

}
