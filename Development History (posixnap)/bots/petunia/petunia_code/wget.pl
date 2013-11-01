code
# extremely simple. gets a page off the internet
# and returns it to the requesting user in a message.
sub wget {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "wget" if @_ == 0;
  return unless $thismsg =~ /^:wget /;
  my @suffixes = qw{
    php cfm html htm shtml jsp cgi pl com de cx net org mil
    gov [0-9] txt
  }; # these really wind up being regex's
  my $suffix = join "|", @suffixes;
  $suffix = qr{$suffix};
  return unless $thismsg =~ /$suffix\/?$/;
  my ($tograb) = $thismsg =~ /^:wget (.*)/;
  #warn "'$tograb'\n";
  return unless $tograb;
  use LWP::Simple;
  use Text::Wrapper;
  my $page = get("$tograb");
  my $wrapper = Text::Wrapper -> new();
  $wrapper -> columns(75);
  1 while $page =~ s/<[^>]+?>//g;
  1 while $page =~ s/&[^;]+?;/ /g;
  my $clean = $wrapper -> wrap($page);
  #print Dumper \$clean;
  lineitemveto($clean, "private", $thisuser);
  return 1;
}

(1 row)
