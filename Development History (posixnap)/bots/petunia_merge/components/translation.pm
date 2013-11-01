use WWW::Babelfish;
use warnings;
use strict;
use constant FAILURE => 0;
use constant SUCCESS => 255;
our $fishy = new WWW::Babelfish;
our @langs = $fishy -> languages();
our %lang_hash = map { lc substr ($_, 0, 2) => $_ } @langs;
our $babel_dbh = ${ utility::new_dbh_handle() };

sub cache {
	my ($from_lang, $to_lang, $trans, $trans_from) = (@_);
	my $cache_sth = $babel_dbh -> prepare(qq{
		insert into translations (fromlanguage, tolanguage, translation,
			trans_from) values (?, ?, ?, ?)
	});
	$cache_sth -> execute($from_lang, $to_lang, $trans, $trans_from);
}

sub is_cached {
	my ($from_lang, $to_lang, $trans_from) = (@_);

	my( $checker_sth, $seen );
	
	$checker_sth = $babel_dbh -> prepare(q{
		select translation from translations 
			where fromlanguage = ? and tolanguage = ?
			and upper(trans_from) = upper(?)
		});
	$checker_sth -> execute($from_lang, $to_lang, $trans_from);
	($seen) = map { @{ $_ } } @{ $checker_sth -> fetchall_arrayref() };

	return $seen ? $seen.' (cached)' : undef;

}

sub lang_abbrev {
	my ($target) = (@_);
	return $lang_hash{$target} ? $lang_hash{$target} : $target;
}

sub translate {
	my ($from_lang, $to_lang, $text) = (@_);

	$from_lang = lang_abbrev( $from_lang );
	$to_lang = lang_abbrev( $to_lang );

	my $output;

	if ($output = is_cached( @_ )) {
		return $output; 
	}

	$output = $fishy -> translate(
		source => $from_lang, destination => $to_lang, text => $text
	);

	if (not $output or $output =~ /&nbsp;/) {
		return 'Babelfish sucks ass.';
	}
	else {
		cache($from_lang, $to_lang, $output, $text);
		return $output;
	}
	return undef;
}

sub parse {
  my ($thischan, $thisuser, $thismsg) = (@_);
	my ($from_lang, $to_lang, $text) = $thismsg =~ /^:xlate\s(\S+)\s(\S+)\s(.*)/;
	return unless (defined $from_lang and defined $to_lang and defined $text);
	utility::spew( $thischan, $thisuser, translate( $from_lang, $to_lang, $text ) );
}

sub do_langs {
	my ($thischan, $thisuser, $thismsg) = (@_);
	return unless $thismsg eq ":langs";
	utility::spew( $thischan, $thisuser, join ", ", @langs );
}

sub public {
	do_langs( $_ );
	parse( @_ );
}

sub private {
	do_langs( $_ );
	parse( @_ );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
:xlate [ fromlang ] [ tolang ] [ text ]
:langs [ no arguments ] returns languages available.
HELP
}
