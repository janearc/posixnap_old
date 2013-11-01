code
sub xxbone {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "xxbone" if @_ == 0;
  return unless $thismsg =~ /^:xxbone /;
  my ($language, $unwitting_victim) = $thismsg =~ /^:xxbone\s+(\w+)\s+([\s\S]+)/;
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
	my $inserter = $dbh -> prepare(qq{
		insert into translations (fromlanguage, tolanguage, trans_from, translation)
			values (?, ?, ?, ?)
	});
  my $output = $fishy -> translate (
    source => 'English', destination => $language, 'text' => $phrase
  );
	$inserter -> execute("English", $language, $phrase, $output);
	my $o_output = $output;
  $output = $fishy -> translate (
    source => $language, destination => 'English', 'text' => $o_output
  );
	$inserter -> execute($language, "English", $o_output, $output);
  return 0 if !$output or $output =~ /^\s+$/;
  if ($output =~ /&nbsp;/) {
    $nap -> public_message("Babelfish sucks ass.");
    return 1;
  }
  $nap -> public_message($output);
  return 1;
}

(1 row)
