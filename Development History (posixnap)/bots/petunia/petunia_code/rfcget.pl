code
# grab an rfc, send it to a user.
sub rfcget {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "rfcget" if @_ == 0;
  return unless $thismsg =~ /^:rfc(?:get)? /;
  my ($rfc) = $thismsg =~ /^:rfc(?:get)? (?:rfc)?(\d{1,4})/i;

  if ($rfc < 3000 and $rfc) {
    use Net::FTP;
    my $ftp = Net::FTP->new("ftp.isi.edu", Debug => 0);
    $ftp -> login("anonymous",'analpleasures@');
    $ftp -> cwd("/in-notes");
    if (not $ftp -> get("rfc$rfc.txt") ) {
      $nap -> public_message("rfc$rfc not available.");
      $ftp -> quit;
      return 0;
    }
    else {
      local $/ = undef;
      if (not open RFC, "<rfc$rfc.txt") {
        $nap -> public_message("rfc$rfc not successfully retreived.");
        qx"rfc$rfc.txt";
        return 0;
      }
      my $text = <RFC>;
      close RFC;
      1 while $text =~ s/^\s+$//g;
      lineitemveto($text, "private", $thisuser);
    }
    $ftp -> quit;
    return 1;
  }
  return 1;
}

(1 row)
