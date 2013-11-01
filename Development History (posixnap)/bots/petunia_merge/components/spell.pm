
sub public {
	use Text::Ispell qw( spellcheck );
	my ($thischan, $thisuser, $thismsg) = @_;
	return unless $thismsg =~ /^:spell/;
	my ($user) = $thismsg =~ /^:spell\s+(.*)$/;
	$user =~ s/\s+//g;
	my $q_sth = ${ utility::new_dbh_handle() } -> prepare(
                "select who, quip from log
                where who ~* '$user' order by stamp desc limit 1"
        );
	$q_sth->execute;
	my $tospell = $q_sth -> fetchall_arrayref() -> [0];
	utility::spew ( $tospell->[0] . " " . $tospell->[1] );
        Text::Ispell::allow_compounds(1);
	my ($statement, $ms);
        for my $r ( spellcheck( $tospell->[1] ) ) {
          if ( $r->{'type'} eq 'ok' ) {
            # as in the case of 'hello'
		$statement = $statement . $r->{'term'} . " ";
          }
          elsif ( $r->{'type'} eq 'root' ) {
            # as in the case of 'hacking'
		$statement = $statement . $r->{'term'} . " ";;
          }
          elsif ( $r->{'type'} eq 'miss' ) {
            # as in the case of 'perl'
		$statement = $statement . uc($r->{'term'} . " ");
		$ms++;
          }
          elsif ( $r->{'type'} eq 'guess' ) {
            # as in the case of 'salmoning'
		$statement = $statement . uc($r->{'term'} . " ");
		$ms++;
          }
          elsif ( $r->{'type'} eq 'compound' ) {
            # as in the case of 'fruithammer'
		$statement = $statement . $r->{'term'} . " ";
          }
          elsif ( $r->{'type'} eq 'none' ) {
            # as in the case of 'shrdlu'
		$statement = $statement . uc($r->{'term'} . " ");
		$ms++;
          }
          # and numbers are skipped entirely, as in the case of 42.
        }
	utility::spew( $thischan, $thisuser, "<" . $tospell->[0] . "> " . $statement );
	$ms = "no" unless $ms;
	utility::spew( $thischan, $thisuser, $tospell->[0] . " had $ms unknown or misspelled words." );
}

sub private {
	()
}

sub emote {
	()
}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) ,<<"HELP";
:spell <nick> will look at the specified nick's last statement and attempt to correct the spelling.
HELP
}

1;
