code
# punish a user for meeting a certain regexp. useless
# except for simple.
sub punish_user {
  my ($thischan, $thisuser, $thismsg) = (@_);
  return "punish_user" if @_ == 0;
  my %users = (
    'simple' => { freq => 1, expr => '([A-Z]+|[Ff][A4a][gG]|[Gg][4aA][Yy]|[nN][iI1][6gG]+|f a g).*?' },
    'aalib' => { freq => 1, expr => '^:xbone ' },
    'dusk' => { freq => 1, expr => '0wn1j' },
  );
  foreach my $user (keys %users) {
    next unless $thisuser =~ /$user/i;
    my $hRef = $users{$user};
    my $freq = $hRef -> {freq};
    my $expr = $hRef -> {expr};
    $expr = qr{$expr};
    my $count = $thismsg =~ /$expr/;
    if ($freq <= $count) {
      # baaaad user!
      $nap -> public_message("baaaad user, $thisuser!!!");
      $nap -> send(829, "$thischan $thisuser");
      return 1;
    }
  }
  return 0;
}

(1 row)
