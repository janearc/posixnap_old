# Simple (?) conversion routine.
# If you add a function, add it to @convs in convert(). The calling convention
# is described there.

use strict;
use warnings;

# Hash of SI prefixes. If you need anything more, then we need Math::BigInt.
# Or so I would assume.
my %si = (
    T => 1_000_000_000_000,
    G => 1_000_000_000,
    M => 1_000_000,
    k => 1_000,
    h => 100,
    da => 10,
    d => 0.1,
    c => 0.01,
    m => 0.001,
    u => 0.000_001,
    n => 0.000_000_001,
    p => 0.000_000_000_001,
);


# converts celsius to fahrenheit and vice versa
sub conv_c2f {
    my( $from, $to, $what ) = @_;
    if( $from =~ /C/i ) { return( ($what * 9 / 5 + 32 ) . $to) }
    else { return( (($what - 32) * 5 / 9 ) . $to) }
}


# converts meters (and portions thereof) to inches
sub conv_m2in {
    my( $from, $to, $what, $mfrom, $mto ) = @_;
    if( scalar @$mfrom && defined $$mfrom[0] ) {
	if( defined $si{$$mfrom[0]} ) {
	    $what *= $si{$$mfrom[0]};
	}
	else { return undef }
    }
    elsif( scalar @$mto && defined $$mto[0] ) {
	if( defined $si{$$mto[0]} ) {
	    $what /= $si{$$mto[0]};
	}
	else { return undef }
    }

    return ($from =~ /m/ ? $what / 0.0254 : $what * 0.0254) . "$to";
}


# converts metric to feet
sub conv_m2ft {
    my( $from, $to, $what ) = @_;
    if( $from =~ /ft/ ) { $from = 'in' }
    else { $to = 'in' }
    my $val = conv_m2in( $from, $to, @_[2..5] );
    $val =~ s/[^\d+.-]+//; # since conv_m2in appends a unit
    return $from eq 'in' ? ($val * 12) . $to : $val / 12 . 'ft';
}


sub public {
    convert( @_ );
}

sub private {
    convert( @_ );
}

sub emote {
}


# The parser.
sub convert {
    my( $thischan, $thisuser, $thismsg ) = @_;
    return unless my( $what, $from, $to ) = $thismsg =~
	/^:convert\s+([-+]?(?:\d+|(?:\d+)?.\d+))(\w+)\s+(\w+)$/i;

    # When adding a new function, fill out this form (#2 pencil please).
    my @convs = (
	# to regex,	    from regex,		function
	[ qr/^C$/i,	    qr/^F$/i,		\&conv_c2f ],
	[ qr/^(..?)?m$/,    qr/^in(?:ch)?$/,	\&conv_m2in ],
	[ qr/^(..?)?m$/,    qr/^ft$/,		\&conv_m2ft ],
    );

    # ugly? yeah :)
    # each function in the above array is called as follows:
    # from_type, to_type, value_to_convert, from_matches, to_matches
    # it's really not that bad. gross though.
    my $ret;
    foreach( @convs ) {
	my( @mto, @mfrom ); # collects any matches you might put into the
			    # regex

	# Yikes. Attempt to match each re in turn, possibly swapping to and
	# from to do so. Account for this in the function please.
	if( ((@mfrom) = ($from =~ $$_[0])) and (@mto = ($to =~ $$_[1])) 
	    or (@mto = ($to =~ $$_[0])) and (@mfrom = ($from =~ $$_[1]))) {

	    @mfrom = "@mfrom" eq '1' ? () : @mfrom; # nuke if "empty"
	    @mto = "@mto" eq '1' ? () : @mto;	    # ditto
	    $ret = &{ $$_[2] }($from, $to, $what, \@mfrom, \@mto ); # go for it
	    last;
	}
    }

    # ...and finish up. If you might be returning a value, please append
    # something to it (even a space will do) if it might evaluate to false.
    if( $ret ) {
	utility::spew( $thischan, $thisuser, $ret );
	return 1;
    }

    return 0;

}


1;
