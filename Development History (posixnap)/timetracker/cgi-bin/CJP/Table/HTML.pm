package CJP::Table::HTML;

use warnings;
use strict;

# new( colnames => [ 'Foo', 'Bar' ], rows => [
# 	[ Baz, Bletch ],
# 	[ Qip, Quux ],
# ]);
sub new { 
	my $self = shift;
	my %args = @_;

	return bless { 
		colnames => [ ],
		rows => [ [ ] ],
	}, $self;

}
