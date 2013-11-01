code
# pickup lines guaranteed to get something thrown in your face
# ... in almost any country.
sub xbone {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "xbone" if @_ == 0;
  return unless $thismsg =~ /^:xbone /;
  my ($language, $unwitting_victim) = $thismsg =~ /^:xbone\s+(\w+)\s+([\s\S]+)/;
  return 0 unless $unwitting_victim and $unwitting_victim !~ /^\s/;
  use Bone::Easy;
  use WWW::Babelfish;
  my $phrase = pickup;
  my $fishy = new WWW::Babelfish;
	my @langs = $fishy -> languages();

	my %lang_hash = map {
		lc scalar substr ($_, 0, 2) => $_
	} @langs;
	$language = $lang_hash{$language} || $language;
  my $output = $fishy -> translate (
    source => 'English', destination => $language, 'text' => $phrase
  );
  return 0 if !$output or $output =~ /^\s+$/;
  if ($output =~ /&nbsp;/) {
    $nap -> public_message("Babelfish sucks ass.");
    return 1;
  }
  $nap -> public_message($output);
	my $inserter = $dbh -> prepare(qq{
		insert into translations (fromlanguage, tolanguage, trans_from, translation)
			values (?, ?, ?, ?)
	});
	$inserter -> execute("English", $language, $phrase, $output);
  return 1;
}

(1 row)
