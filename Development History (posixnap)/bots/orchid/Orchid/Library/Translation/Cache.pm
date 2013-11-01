package Orchid::Library::Translation::Cache;

=head1 NAME

Orchid::Library::Translation::Cache

=cut

=head1 ABSTRACT

Another "back end" module for the Orchid::Library::Translation suite,
designed to cache to the database. This way, we prevent altavista from
parsing our varied come-ons and other insipid translations.

No user serviceable parts inside.

=cut

use warnings;
use strict;
use POE qw{ Session };

our %sth = (
	cache => qw{ 
		insert into translations (fromlanguage, tolanguage, translation,
			trans_from) values (?, ?, ?, ?)
	},
	check => qw{
		select translation from translations 
			where fromlanguage = ? and tolanguage = ?
			and upper(trans_from) = upper(?)
	},
	object => { },
)

=head1 SESSIONS

=cut

=item OrchidBabelfishCache

Our "main" session, whose states include the various modules necessary for
caching.

=cut

POE::Session -> create (
	inline_states => {
		_start => sub {
			# XXX: This is where we initialize LaDBI (or whatever Rocco is pitching today)
			my ($kernel) = @_[ KERNEL ];
			$kernel -> alias_set( 'OrchidBabelfishCache' );

			# XXX: something like this:
			# perl makes me squishy in all the right places.
			%{ $sth{object} } = map {
				$_ => $dbh -> prepare( $sth{$_} )
			} keys %{ $sth{object} }; 
		},

=head1 STATES

=cut

=item cache

C<cache> is where we pass data that has been translated by the Translation
library. It expects to be passed four arguments:

	the language translated from
	the language translated to
	the translated text
	the original text

After the arguments are passed, it will simply foist them off on the database,
and let somebody else handle it. You should not expect any sort of return from
this module, except perhaps a loud death if the database is not working
properly.

=cut
	
		# {{{1
		cache => sub {
			my ($fromLang, $toLang, $translated, $transFrom) = @_[ ARG0 .. $#_ ];
			# XXX: at this point we do something like:
			$sth{object} -> {cache} -> execute( 
				$fromLang, $toLang, $translated, $transFrom
			);
		},
		# }}}1

=item is_cached

In C<is_cached> we determine whether or not something has actually been
cached. If not, we pass it to the C<cache> state, where the database handles
things. If it is cached, we simply return as if nothing had happened.

C<is_cached> would like to be passed four variables, as well:

	the language translated from
	the language translated to
	the translated text
	the original text

=cut
	
		# {{{1
		is_cached => sub {
			my ($fromLang, $toLang, $translated, $transFrom) = @_[ ARG0 .. $#_ ];
			# XXX: at this point we do something like:
			$sth{object} -> {check} -> execute( 
				$fromLang, $toLang, $translated, $transFrom
			);

			# XXX: some check for trueness.
			# XXX: if true, just return
			# XXX: if false, post to $_[ SESSION ], 'cache' ...
		},
		# }}}1

	}
}

1;

=head1 LICENSE

You should have received a license with this software. If you did
not, please remove this software entirely, and contact the author,
Alex Avriette - alex@posixnap.net.

=cut
