use WWW::Babelfish;
use Bone::Easy;
use warnings;
use strict;
use constant FAILURE => 0;
use constant SUCCESS => 255;
our $fishy = new WWW::Babelfish;
our @langs = $fishy -> languages();
our %lang_hash = map { lc substr ($_, 0, 2) => $_ } @langs;
our $bone_dbh = ${ utility::new_dbh_handle() };

sub cache {
	my ($from_lang, $to_lang, $trans) = (@_);
	my $cache_sth = $bone_dbh -> prepare(qq{
		insert into translations (fromlanguage, tolanguage, translation)
			values (?, ?, ?)
	});
	$cache_sth -> execute($from_lang, $to_lang, $trans);
}

sub is_cached {
	my ($from_lang, $to_lang, $trans) = (@_);

	my $checker_sth = $bone_dbh -> prepare(qq{
		select translation from translations 
			where fromlanguage = ? and tolanguage = ? and upper(trans_from) = upper(?)
	});

	my $seen; $checker_sth -> execute($from_lang, $to_lang, $trans);

	($seen) = map { @{ $_ } } @{ $checker_sth -> fetchall_arrayref() };

	return $seen || undef;
}

sub lang_abbrev {
	my ($target) = (@_);
	return $lang_hash{$target} ? $lang_hash{$target} : $target;
}

sub translate {
	my ($from_lang, $to_lang, $text) = (@_);

	$from_lang = lang_abbrev( $from_lang );
	$to_lang = lang_abbrev( $to_lang );

	if (is_cached( @_ )) {
		return is_cached( @_ ) 
	}

	my $output = $fishy -> translate(
		source => $from_lang, destination => $to_lang, text => $text
	);

	if ($output =~ /&nbsp;/) {
		return "Babelfish sucks ass.";
	}
	else {
		cache($from_lang, $to_lang, $output);
		return $output;
	}
	return undef;
}

sub xxbone {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless my ($to_lang, $unwitting_victim) = $thismsg =~ /^:xxbone\s+(\w+)\s+([\s\S]+)/;
  return 0 unless $unwitting_victim and $unwitting_victim !~ /^\s/;

  my $phrase = pickup();

	my $outbound = translate( 'English', $to_lang, $phrase );
	my $inbound = translate( $to_lang, 'English', $outbound );
	
	$inbound =~ s/\n/ /g;
	
	utility::spew( $thischan, $thisuser, $inbound );
}

sub xbone {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless my ($to_lang, $unwitting_victim) = $thismsg =~ /^:xbone\s+(\w+)\s+([\s\S]+)/;
  return unless $unwitting_victim and $unwitting_victim !~ /^\s/;

	utility::spew( $thischan, $thisuser, translate( 'English', $to_lang, pickup() ) );
}

sub bone {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return unless my ($unwitting_victim) = $thismsg =~ /^:bone\s+([\s\S]+)/;
  return unless $unwitting_victim and $unwitting_victim !~ /^\s/;

  utility::spew( $thischan, $thisuser, pickup() );
}

sub public {
	bone( @_ );
	xbone( @_ );
	xxbone( @_ );
}

sub private {
	bone( @_ );
	xbone( @_ );
	xxbone( @_ );
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::private_spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
bone contains bone, xbone, and xxbone. examples:
:bone [ something ] - generate a pickup line
:xbone [ language ] [ something ] - generate a pickup line in a foreign language
:xxbone [ language ] [ something ] - generate a pickup line in a foreign language, translate it through babelfish, and back to english. can be quite amusing.
HELP
}
