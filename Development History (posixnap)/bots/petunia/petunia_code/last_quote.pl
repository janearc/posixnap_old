code
# get a simple yahoo quote
sub last_quote {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "last_quote" if @_ == 0;
  return 0 unless $thismsg =~ /^:last/;
  my ($symbol) = $thismsg =~ /^:last\s+(\w+)/;
  use Finance::Quote;
  my $query = Finance::Quote -> new();
  $symbol =~ y/a-z/A-Z/; # yahoo likes uppercase
  my %quote = $query -> yahoo($symbol);
  my $name = $quote{$symbol, "name"};
  my $last = $quote{$symbol, "last"};
  $name = ucfirst_words($name);
  if ($last == 0) {
    $nap -> public_message("Unknown symbol $symbol");
    return 1;
  }
  $nap -> public_message("$name last traded at $last");
  return 1;
}

(1 row)
