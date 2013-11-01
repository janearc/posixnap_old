package Orchid::Library::Translation;

=head1 NAME

Orchid::Library::Translation

=cut

=head1 ABSTRACT

The Orchid::Library::Translation module provides a translation 
facility for the Orchid project. It is composed of a single primary
session and several child sessions, as well as a single state through
which to pass translation requests. The module does the rest, 
including the http stuff and scraping.

=cut

use warnings;
use strict;
use Carp;

use Orchid::Library::Translation::Cache;
use HTML::TokeParser;
use Memoize;
use HTTP::Request::Common qw{ GET POST };
use POE qw{ Component::Client::HTTP };

our $babelfishUrl = qw{ http://babelfish.altavista.com/babelfish/tr };

=head1 SYNOPSIS

  use Orchid::Library::Translation;
	use POE;

	POE::Kernel -> post( 
		'English', 'Spanish', 
		'My name is Inigo Montoya. You killed my father. Prepare to die.',
	);

	# or...

	my $translator = Orchid::Library::Translation -> new()
	print $translator -> translate(
		'Spanish', 'English',
		'Buenas tardes amigo',
	);

=head1 SESSIONS

=cut

=item OrchidBabelfishParent

C<OrchidBabelfishParent> is the session to which you will be posting
requests for translation.

=cut

POE::Session -> create (
	inline_states => {

		# Init stuff should go here.
		_start => sub { 
			my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
			$kernel -> alias_set( 'OrchidBabelfishParent' );
		},
		
=head1 STATES

=cut

=item translate

C<translate> expects to be passed three parameters, 

	language translating from
	language translating to
	text to translate

The scraping, http requests, and parsing will be handled by the
module, and it will yield the rest of the translation in a manner
that is as yet unspecified.

=cut

		# {{{1
		translate => sub {
			my ($kernel) = @_[ KERNEL ];
			$kernel -> post( 
				'OrchidBabelfishScrape', 'requestTranslation', @_[ ARG0, ARG1, ARG2 ]
			);
			# XXX: caching goes here
		}
		# }}}1
	} 	
);

# XXX: This needs to be made aware of the Cacher. Also,
# it needs to tell the kernel to post a return for the
# bot. Perhaps there should be a 'spew' alias with a 
# 'public', 'private', 'notice', etc state.
sub translate {
	my ($self, $fromLang, $toLang, $inText) = (@_);

	# We need to ensure that after passing this to requestTranslation,
	# that doBabelfishTranslation actually returns to us our translated
	# text.
	POE::Kernel -> post( 
		'OrchidBabelfishScrape',
		'requestTranslation',
		( $fromLang, $toLang, $inText )
	); 

	$fromLang = lang_abbrev( $fromLang );
	$toLang = lang_abbrev( $toLang );

	my $outText;

	if ($outText = isCached( @_ )) {
		return $outText; 
	}

	if (not $output or $output =~ /&nbsp;/) {
		return 'Babelfish sucks ass.';
	}
	else {
		cache($fromLang, $toLang, $outText, $inText);
		return $outText;
	}
	return undef;
}

=head1 HELP

:xlate [ frontlang ] [ tolang ] [ text ]
:langs [ no arguments ] returns languages available.

=cut
