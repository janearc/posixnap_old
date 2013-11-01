code
# respond with the number of userseconds we've consumed.
sub pig {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "pig" if @_ == 0;
  return unless $thismsg =~ /^:pig/;
  use BSD::Resource;
  my           ($usertime, $systemtime,
                $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
                $inblock, $oublock, $msgsnd, $msgrcv,
                $nsignals, $nvcsw, $nivcsw) = getrusage();
  $nap -> public_message("$usertime userseconds consumed thus far.");
}

(1 row)
