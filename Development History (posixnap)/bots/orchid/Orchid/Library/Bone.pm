package Orchid::Library::Bone;

=head1 NAME

Orchid::Library::Bone

=cut

=head1 ABSTRACT

A module to generate pickup lines, guaranteed to get a drink
thrown in your face. In a non-blocking kind of way.

=cut

=head1 THEORY OF OPERATION

Since this module takes no input, all that is required is a 
call to one of the three states defined in the C<OrchidBoneParent>
session.

=cut

use warnings;
use strict;
use Bone::Easy;
use POE qw{ Session }; 
use Orchid::Library::Translation;

=head1 SESSIONS

=cut

=item OrchidBoneParent

This is the "main" session of this module.

=cut

POE::Session -> create (
	inline_states => {
		
		# Init stuff should go here.
		_start => sub { $_[KERNEL] -> alias_set( 'OrchidBoneParent' ) },

=head1 STATES

=cut

=item bone

The C<bone> state issues a request to the bone provider, which will
be yielded to the session's caller. Takes no arguments.

=cut

		# {{{1
		bone => sub { 
			my ($kernel, $undercheek) = @_[ KERNEL, HEAP ];
			my $victim = $_[ SENDER ]; # this is who wants to hear from us.
		},
		# xbone }}}1

=item xbone

C<xbone> calls down a bone from the provider as well as passing it
through the C<Orchid::Library::Translation> hierarchy for eventual
return to the user as a translated string. Requires one argument,
the language into which it is to be translated into.

=cut

		# {{{1
		xbone => sub { 
			my ($kernel, $undercheek) = @_[ KERNEL, HEAP ];
			my $victim = $_[ SENDER ]; # this is who wants to hear from us.
			my $toLang = $_[ ARG0 ]; # language we wish to translate into

			# We're done once this is sent off.
			$kernel -> post( 'OrchidBabelfishScrape', 'requestTranslation',
				'en', 
				$toLang,
			);

		},
		# xbone }}}1

=item xxbone

C<xxbone> is even less useful than the previous C<xbone> method.
It calls the original C<bone> method (sort of), and then passes it
to the Translation library. To further complicate matters, it
translates the translation returned back into the source language
(English).

A note to users expecting to gain further bones out of this: You
will not.  This module is best put to use generating gibberish.

=cut

		# {{{1
		xxbone => sub { 
			# XXX: ok, so i'm stumped. we send it off to babelfish, but what do
			# XXX: we do when it comes back? we need to translate it _again_.
			# XXX: this requires some thinking in the babelfish lib.
		},
		# xbone }}}1
	}
);

sub new { bless {}, shift }

sub bone {
	return pickup;
}

1;
