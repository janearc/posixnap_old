code
sub select_map {
  # we do this for our switches
  my (@forebuffer, @aftbuffer, $fore, $aft, $pattern);
  return "select_map" if @_ == 0;
  my ($thischan, $thisuser, $thismsg) = (@_);
  #my $ad = qr{[\w\s\d[:punct:]]+};
  my ($fields, $query, $switch) = $thismsg =~ /^:map !([^!]+)!\s+!([^!]+)!/;
  my $switching = 1 if $switch;
  my @bad_queries = qw{
    update
    revoke
    insert
    delete
    drop
    grant
    create
    exec
    commit
    vacuum
    into
    truncate
    alter
  };
  my $bad_q = join "|", @bad_queries;
  return unless ($fields and $query);
  return if $query =~ /$bad_q/i;

  warn "proceeding...\n";

  $fields =~ y/!//d;
  my @cols = split /,/, $fields;

  # return error unless we get at least two columns
  if (@cols < 1) {
    #use Data::Dumper; print Dumper \($query, $switch);
    $nap -> public_message( qq{:map !col1,col2,col3! !query!} );
    return 1;
  }
  my $out;
  foreach my $row (@{ $dbh -> selectall_arrayref($query) }) {
    if (@{ $row } != @cols) {
      $nap -> public_message( qq{:map !col1,col2,col3! !query!} );
      return 0;
    }
    $out .= join " ", map { "[ $_ ]" } @{ $row };
    $out .= "\n";
  }

  lineitemveto($out);

  return 1;
  sub process_switch {
    my $arg = shift;
  # my $pat = $main::select_map::pattern;
  # ($pat) = $arg = /!?|\s+grep\s+(.*)!?/;
  # carp "grepping for $pat\n";
  }

}

(1 row)
