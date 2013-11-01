
sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::private_spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
select_map issues queries against whichever database the bot is attached to.
please note this can be changed in realtime, so your data may be inconsistent.
in general, it follows the form:
:map !column_name, column_name_2! !select column_name, column_name2 from tablename limit 4!
you can only return four rows, so you might as well use a limit.
HELP
}

sub select_map {
  # we do this for our switches
  my (@forebuffer, @aftbuffer, $fore, $aft, $pattern);
  return 0 if @_ == 0;
  my ($thischan, $thisuser, $thismsg) = (@_);
  #my $ad = qr{[\w\s\d[:punct:]]+};
  my ($fields, $query, $switch) = $thismsg =~ /^:map !([^!]+)!\s+!([^!]+)!/;
  my $switching = 1 if $switch;
  my @bad_queries = qw{
    copy
    lock
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
    utility::spew( $thischan, $thisuser, qq{:map !col1,col2,col3! !query!} );
    return 0;
  }

  my $out;
  my $dbh = ${ utility::new_dbh_handle() };
  my $rows = $dbh -> selectall_arrayref($query);

  unless (defined $rows) {
    utility::spew( $thischan, $thisuser, "query failed: " 
  		. $DBI::errstr);
    return 0;
  }

  if( not $rows->[0] ) {
    utility::spew( $thischan, $thisuser, 'no rows returned' );
    return 0;
  }

  foreach my $row ( @{ $rows }[0 .. 4] ) {
    unless (defined @{ $row } ) {
	return 0
    }
    elsif (@{ $row } != @cols ) {
      utility::spew( $thischan, $thisuser, qq{:map !col1,col2,col3! !query! } );
      return 0;
    }
    else {
	$out = join " ", map { "[ $_ ]" } @{ $row };
	#$out .= "\n";
	utility::spew( $thischan, $thisuser, $out );
    }
  }

  # this should be part of spew
  #lineitemveto($out);
  #utility::spew( $thischan, $thisuser, $out );

  return 1;
  sub process_switch {
    my $arg = shift;
  # my $pat = $main::select_map::pattern;
  # ($pat) = $arg = /!?|\s+grep\s+(.*)!?/;
  # carp "grepping for $pat\n";
  }

}


sub public {
    select_map( @_ );
}

sub private {
    select_map( @_ );
}

sub emote {
}

1;
