package CJP::Bee;

use warnings;
use strict;

sub new { 
	my $self = shift;
	my @args = @_;

	return bless { 
		bee => '',
		beeid => '',
	}, $self;

}
