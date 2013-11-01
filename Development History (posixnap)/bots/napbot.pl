#!/usr/bin/perl -w

use strict;
use MP3::Napster;
use LWP::UserAgent;
# use Data::Dumper;
use Getopt::Std;


$SIG{INT} = \&hangup;		# on SIGINT, disconnect
$SIG{TERM} = \&hangup;
$SIG{HUP} = \&reconnect;	# sometimes doesn't die when it should, force it
our (%funcs, $nap, %opts);

# extended help likely shouldn't be in here, too much loaded in to memory
%funcs = ( weather  => [ \&do_weather, 
			 'returns the weather for a given city',
			 "Canada/US: <city>, <prov>, <cc>\n"
			 . "\t   <http://weather.ec.gc.ca/>\n"
			 . "Elsewhere: <city>, <cc>\n"
			 . "\t   <http://weather.noaa.gov/>" ],
	   weather2 => [ \&do_weather2, 'testing, don\'t use',
	   		 'what did i say?' ],
	   buh      => [ \&do_buh, 'buh!', 'buh. damnit.' ],
	   service  => [ \&do_service,
	   		 'returns the service for a given port',
			 'Returns services listed for the given port number' ],
	   port     => [ \&do_port,
	   		 'returns the port for a given service',
			 'Returns ports listed for given services. You may use'
			 . ' regexes.' ],
	   apt      => [ \&do_apt, 'returns a description of a program',
	   		 "Returns apt\'s description for a given package.\n"
			 . "\t:apt more <package> for the full description.\n"
			 . "\tYou may use regexes." ],
	   currency => [ \&do_currency, 'convert from one currency to another',
	                 '<from-cc> <to-cc> <amount>' ],
	   whatis   => [ \&do_whatis, 'returns the whatis for a program',
	   		 '<program-name>, only 0-9A-Za-z_ please' ],
	   temp	    => [ \&do_temp,
	   		 'returns the (C|F) temperature in (F|C)',
			 '<from><C|F>' ],
	   cc	    => [ \&do_cc, 'returns the country code for a country',
	   		 "it\'s pretty straight forward dude" ],
	   country  => [ \&do_country, 'returns the country for a country code',
	   		 "it\'s pretty straight forward dude" ],
	   how      => [ \&do_help,
	   		 'returns extended help for a function',
			 'Extended help: :how <function>' ],
	   ip2int   => [ \&do_ip2int, 'returns the integer equivalent of an ip'
			 . ' address', 'if you can\'t figure this out...' ],
	 );

our $channel = '#posix';
our $nick = 'howitzer';

options();

my $server = 'localhost:7777';
if ($ARGV[1]) { $server = $ARGV[0] . ':' . $ARGV[1] }

my $password = get_pass();

while (1) {
	$nap = MP3::Napster->new( $server );
	
	if ($nap) {

		msg_log( "connected to $server.\n" );
		
		$nap->callback( PRIVATE_MESSAGE, \&message );
		$nap->callback( PUBLIC_MESSAGE, \&message );
		$nap->callback( INVALID_ENTITY, \&parted );
		$nap->callback( 316, \&parted ); # killed

		my $logged_in = -1;
		while( $logged_in == -1 ) {
			$logged_in = bot_login($password);
			if( $logged_in > 0 ) {
				chan_join( "joining $channel..." );
				$nap->error(''); #clear any errors
				$nap->run;
				msg_log( "disconnected: " .
					$nap->error() ? $nap->error()
						      : "no reason given"
					. "\n" );
			} elsif( $logged_in == -1 ) {
				# i'm really sorry that i had to do it this way.
				# please accept my apologies :(
				$nap->disconnect;
				$password = get_pass();
				$nap = MP3::Napster->new( $server );
			}
		}

	} else { msg_log( "couldn't connect to $server.\n" ) }
	
	msg_log( "waiting 180s before attempting to connect.\n" );
	sleep 180; # sleep for 3 minutes before attempting to log in again.
}


sub get_pass {
	print 'Password: ';
	system "stty -echo </dev/tty" unless $ENV{EMACS};
	$_ = <STDIN>;
	system "stty echo </dev/tty" unless $ENV{EMACS};
	print "\n";
	chomp;
	return $_;
}


sub options {
	getopts( 'l:n:c:q', \%opts );
	
	if( $opts{l} ) {
		if( not open( LOGFILE, '>>' . $opts{l} )) {
			print "could not open $opts{l} for logging!\n";
			$opts{l} = undef;
		} else {
			print LOGFILE "[ " . localtime(time) . " ]\n";
			close LOGFILE;
		}
	}
	
	if( $_ = $opts{n} ) {
		if( /[^\w\d-]/ ) { die "\"$_\" is not a valid nick." }
		else { $nick = $_ }
	}
	
	if( $_ = $opts{c} ) { $channel = $_ }
}


sub msg_log {
	$_ = $_[0];
	if( $opts{l} ) {
		open( LOGFILE, '>>' . $opts{l} );
		print LOGFILE $_ ;
		close LOGFILE;
	}
	if( !$opts{q} ) { print $_ }
}


sub bot_login {
	msg_log "attempting login... ";
	my $login_string = $nick . ' ' . $_[0] . ' 0 "Crackhed Music'
			   . ' Thiever vP" ' . LINK_CABLE;
	my ($event, $msg) = $nap->send_and_wait( LOGIN, $login_string,
						 [ LOGIN_ACK, LOGIN_ERROR,
						 ERROR ], 10 );
	if( !$event ) {
		if( !$msg ) { msg_log "timed out.\n"; return 0 }
		else {
			msg_log $msg . ".\n";
			if( $msg =~ /Invalid Password/io ) { return -1 }
		}
	} elsif( $event == LOGIN_ACK ) { msg_log "success.\n"; return 1 }
	elsif( $event == LOGIN_ERROR ) { msg_log $msg . "\n"; return 0 }
	else { msg_log "uh... $event($msg)\n"; return 0 }
}


sub parted {
	$_ = $_[2];
	if( /^You were kicked.* (\S+):/o )
		{ chan_join( "kicked by $1, rejoining..." ) }
	elsif( /(\S+) cleared channel $channel:/ )
		{ chan_join( "cleared by $1, rejoining..." ) }
	elsif( /(\S+) killed $nick:/ ) {
		$nap->disconnect ();
		msg_log "killed by $1, reconnecting...\n"
	} elsif( $_[1] == 316 ) {
		$nap->disconnect ();
		msg_log "error: \"$_\" ($_[1]), reconnecting...\n";
	}
}


sub chan_join {
	msg_log $_[0] . "\n";
	$nap->part_channel( $channel ); # in case we've been kicked
	$nap->join_channel( $channel ); # or die( "can't join $channel! " .
				        # $nap->error ? $nap->error : ":(" );
}


sub hangup () {
	if( $nap ) { $nap->disconnect() }
	msg_log "\n";
	if( $opts{l} ) { close( LOGFILE ) }
	exit (0);
}


sub reconnect () {
	if( $nap ) { $nap->disconnect() }
	msg_log "*received a SIGHUP, reconnecting\n";
}


sub wildcard {
	$_ = $_[0];
	s/\*/[^\\s\\t]*/go;
	s/\?/\\w/go;
	return $_;
}


sub message ($) {
	my $args = $_[2];
	my $private = 0;		#public message
	my $returned = undef;
	my ($channel, $nick, $message);
	
	if ($_[1] == 205) {
		$private = 1;
		($nick, $message) = $args =~ /^(\S+) (.+)$/o;
	} else {
		($channel, $nick, $message) =
			$args =~ /^(\S+) (\S+) (.+)$/o;
	}
	
	if ($message) {

		my( $command, $arguments );

		if( $private ) { (($command, $arguments) =
			$message =~ /^(?::)?(\S+)(?:\s+(.+))?$/o) or return;
		} else { (($command, $arguments) = 
			$message =~ /^:(\S+)(?:\s+(.+))?$/o) or return;
		}
	
		#print "$nick ", $channel ? "($channel) " : "", "$command",
		#      $arguments ? ": $arguments" : "";

		my $iscommand = 0;

		foreach my $cmd (keys %funcs) {
			if ($command eq $cmd) {
				msg_log( "$nick " .
					 ($channel ? "($channel) " : "") .
				      	 $command .
					 ($arguments ? ": $arguments" : "") );
				my $cb = $funcs{$cmd}[0];
				$returned = &$cb( $arguments );
				$iscommand = 1;
				last;
			}
		}

		if( !$iscommand ) { return }

		if ($returned) {
		
			# that's right, tabs are a hard 8 characters. be
			# warned.
			$returned =~ s/\t/        /og;
			my @lines = split( /\n/, $returned );
			
			for (my $i=0; $i <= $#lines; $i++) {
				if( $lines[$i] =~ /^ \.$/ ) { $lines[$i] = ' ' }
				if ($private or $#lines >= 10) {
					$nap->private_message
						( $nick, $lines[$i] );
				} else {
					#if( $#lines >= 10 ) {
					#	@lines = ( '(too much to output'
					#		   . ', please use a'
					#		   . ' private message)'
					#		 );
					#}
					$nap->public_message( $lines[$i] );
				}
			}
			
			# no sense flodding the logs; however, i would like to
			# know whether the command returned successfully or
			# not, which is why we print /something/
			msg_log "; $lines[0]" . (($#lines > 1) ? " (more)"
							    : "") . "\n";
			
		} else { msg_log "; null\n" }
	}
		
}


sub do_weather () {

	my ($city, $country, $prov);
	(($city, $prov, $country) =
		$_[0] =~ /^\s*([[:alpha:]\s]+[[:alpha:]])\s*,
			  \s*([[:alpha:]]{2})\s*,
			  \s*([[:alpha:]]{2})\s*$/ox)
		or (($city, $country) = $_[0] =~
			/^([[:alpha:]\s]+[[:alpha:]])\s*,
			 \s*([[:alpha:]]{2})\s*$/ox)
		or return " :how weather";

	my $request;
	my $response;
	my $ua = new LWP::UserAgent;
	my ($weather);

	$prov = uc( $prov );
	$country = uc( $country );

	$city = ucfirst( $city );
	$city =~ s/\s+(\w)/ \u$1/g;

	if ($country eq 'CA') {

		my %provinces = ( BC => 'British+Columbia',
				  AB => 'Alberta',
				  SK => 'Saskatchewan',
				  MB => 'Manitoba',
				  ON => 'Ontario',
				  QC => 'Quebec',
				  NB => 'New+Brunswick',
				  NS => 'Nova+Scotia',
				  PE => 'Prince+Edward+Island',
				  NF => 'Newfoundland',
				  YT => 'Yukon',
				  NT => 'Northwest+Territories',
				  NV => 'Nunavut',
		);
		foreach my $code (keys %provinces) {
			if ($prov eq $code) {
				$prov = $provinces{$code};
				last;
			}
		}
		$city =~ tr/ /+/;
		my $url = "http://weather.ec.gc.ca/wcgi-bin/forecast/"
			. "forecast.cgi?city=" . $city . "&province="
			. $prov;
		$city =~ tr/+/ /; #get rid of the +s for output
		$request = HTTP::Request->new( 'GET', $url );
		$response = $ua->request($request);
		if ($response->is_success) {
			my ($cond, $temp) = $response->content =~
				m{<FONT\sSIZE=-1>.<CENTER><B>([^<]+).+?
				  Temperature:.+?<B>([^<]+)</B>}osx;
			if ($temp) { $weather = $cond . ", " . $temp };
		}
	
	} else {

		#(($city, $country) = $_[0] =~ /^(.+), (.+)$/) or return undef;
		my $url;
		if( $country eq 'US' ) { $url =
			"http://weather.noaa.gov/weather/" . $prov
			. "_cc_us.html" }
		else { $url = "http://weather.noaa.gov/weather/" . $country
			. "_cc.html" }
		$request = HTTP::Request->new( 'GET', $url );
		$response = $ua->request($request);
		if ($response->is_success) {
			my $code;
			# should maybe nest another if?
			if( $response->content =~
				m{<OPTION\sVALUE="(....)">\s$city}is ) {
				$code = $1;
			} else { return "no data for $city" }
			$url = "http://weather.noaa.gov/cgi-bin/call_currwx.pl"
			       . "?cccc=" . $code;
			$request = HTTP::Request->new( 'GET', $url );
			$response = $ua->request( $request );
			if ($response->is_success) {
				($response->content =~
					m{Sky\sconditions\s</FONT></FONT></B>
					  </TD>..<TD><FONT\sFACE="Arial,
					  Helvetica">..(.+?)..</FONT>}osx)
					  and my $cond = $1;
				($response->content =~
					m{Temperature\s</FONT></FONT></B></TD>
					  ..<TD><FONT\sFACE="Arial,Helvetica">
					  ..(.+?)..</FONT>}osx)
					  and my $temp = $1;
				$weather = $cond ? $cond.", ".$temp
						 : $temp
			}
		}
		
	}

	#print $cond." ".$temp."\n";#$response->content; #Dumper( $response );
	return $weather ? $city . ", " . $country . ": " . $weather
		     : "no data for $city";
}


sub do_buh () {
	#return "I'm sorry I cant be party to this.";
	return `/usr/games/fortune -os`;
}


sub do_service () {

	$_[0] =~ /[^\d]/o and return "I think you want the \"port\" function.";
	$_[0] =~ /\(\?\??\{/ and return "That looks like a (?{ CODE }) block.";
	open( SERVICEFILE, "</etc/services" ) or return undef;
	while ($_ = <SERVICEFILE>) {
		my $buh = $_;
		if ( $_ =~ m-^[^#]+\s+$_[0]/- ) {
			close( SERVICEFILE );
			$buh =~ s/\s{2,}|\t+/  /g;
			return $buh;
		}
	}
	close( SERVICEFILE );
	return $_[0] . ": no service"; 

}


sub do_port {

	$_[0] =~ /^\s*\d+\s*$/ and
		return "I think you want the \"service\" function.";
	#$_[0] =~ s/\*/[^\\s\\t]*/go;
	#$_[0] =~ s/\?/./go;
	#$_[0] = wildcard( $_[0] );
	my $found = undef;
	open( PORTFILE, "</etc/services" ) or return undef;
	while( $_ = <PORTFILE> ) {
		if( $_ =~ /^$_[0]\s/i ) {
			s/\s{2,}|\t+/  /og;
			#if( $_[0] =~ /\*/ ) {
			#	#$found ? $found .= ($_ . "\n") : $found = $_;
			$found .= "$_\n";
			#} else {
			#	close( PORTFILE );
			#	return $_;
			#}
		}
	}
	close( PORTFILE );
	return( $found ? $found : "no port" );
}


sub do_help () {
	if ( $_[0] ) {
		($_[0]) = $_[0] =~ /\s*:?(\w+)\s*/;
		foreach my $cmd (keys %funcs) {
			if ($_[0] eq $cmd) {
				return $funcs{$cmd}[2];
			}
		}
	} else {
		my $returnstr = "The following functions are defined:\n";
		foreach my $cmd (keys %funcs) {
			$returnstr .= $cmd . ":" . " "x(11 - length($cmd))
			. $funcs{$cmd}[1] . "\n";
		}
		return $returnstr;
	}
	return "$_[0] is not defined.";
}


sub do_apt () {
	my $package = $_[0];
	my $more = 0;
	if( $package =~ /^more\s+(.+)$/ ) { $more = 1; $package = $1 }
	my $found;
	my $descr;
	my $returned = undef;
	my $pname;
	#$package = wildcard( $package );
	open( APTCACHE, 'dpkg-avail' );
	while( $_ = <APTCACHE> ) {
		#if( $found ) {
		#	if( /^Description: (.+)$/ ) {
		#		if( !$more ) { return "$package: $1" }
		#		else { $returned = "$package: $1\n" }
		#	}
		#	elsif( not /^$/ ) { $returned .= $_ }
		#	else {
		#		close( APTCACHE );
		#		return $returned;
		#	}
		#}
		#if( /^Package: $package$/ ) { $found = 1 }
		if( $found ) {
			if( /^Description: (.+)$/ ) {
				$descr = 1;
				$returned .= "$pname: $1\n";
				if( !$more ) { $found = 0 }
			} elsif( /^$/ ) { $found = 0 }
			elsif( $descr ) { $returned .= $_ }
			#} elsif( not /^$/ and $descr ) { $returned .= $_ }
			#elsif( /^$/ ) { $found = 0 }
		}
		elsif( /^Package: ($package)\n$/ ) {
			$found = 1;
			$descr = 0;
			$pname = $1;
		}
	}
	close( APTCACHE );
	return $returned ? $returned : "can't find package";
}


sub do_currency () {
	( my( $from, $to, $amount ) =
		$_[0] =~ /^\s*([[:alpha:]]{2})\s+([[:alpha:]]{2})\s+
			  (?:\$)?(\d+(.\d+)?|.\d+)\s*$/ox )
		or return ' :how currency';
	
	$from = uc( $from );
	$to = uc( $to );

	# the exchanger is kinda confuddled, make things easy:
	my %countries = ( AR => 'Ar',
			  AU => 'Austra',
			  AT => 'EURO',
			  BS => 'Ba',
			  BE => 'EURO',
			  BR => 'Br',
			  CFA => 'CFA',
			  CFP => 'CFP',
			  CL => 'Chil',
			  CN => 'Chin',
			  HR => 'Cr',
			  CO => 'Co',
			  CZ => 'Cz',
			  DK => 'D',
			  # East Caribbean dollar
			  EURO => 'EURO',
			  FJ => 'Fij',
			  FI => 'EURO',
			  FR => 'EURO',
			  DE => 'EURO',
			  GH => 'Gh',
			  GR => 'EURO',
			  HN => 'Hond',
			  HK => 'Hong',
			  HU => 'Hu',
			  IS => 'Ic',
			  IN => 'Indi',
			  ID => 'Indo',
			  IE => 'EURO',
			  IL => 'Is',
			  IT => 'EURO',
			  JP => 'J',
			  MY => 'Ma',
			  MX => 'Me',
			  MA => 'Mo',
			  MM => 'My',
			  NL => 'Nethe',
			  #AN => 'Neth.',
			  NZ => 'New',
			  NO => 'No',
			  PK => 'Pak',
			  PA => 'Pan',
			  PE => 'Pe',
			  PH => 'Ph',
			  PL => 'Pol',
			  PT => 'EURO',
			  RU => 'R',
			  SG => 'Si',
			  SK => 'Slova',
			  SI => 'Slove',
			  ZA => 'South A',
			  KP => 'South K',
			  ES => 'EURO',
			  LK => 'Sr',
			  SE => 'Swe',
			  CH => 'Swi',
			  TW => 'Ta',
			  TH => 'Th',
			  TT => 'Tr',
			  TN => 'Tun',
			  TR => 'Tur',
			  GB => 'UK',
			  US => 'U.',
			  VE => 'V',
	);

	my( $from_conv, $to_conv );
	my $matched = 0;

	if( $from eq $to ) { return "let's try /different/ countries, hmm?" }
	
	if( $from eq 'CA' ) { $from_conv = 1; $matched++ }
	elsif( $to eq 'CA' ) { $to_conv = 1; $matched++ }
	
	my $ua = new LWP::UserAgent;
	my $request = HTTP::Request->new( 'GET',
		'http://www.bankofcanada.ca/en/exchange.htm' );
	my $response = $ua->request( $request );
	if( $response->is_success ) {
		my ($to_cc, $from_cc);
		my $matched = 0;
		foreach my $code (keys %countries) {
			if( $code eq $from ) {
				$from = $countries{$code};
				$matched++;
			}
			elsif( $code eq $to ) {
				$to = $countries{$code};
				$matched++;
			}

			if( $matched == 2 ) { last }
		}
		($response->content =~ m{<option value=([^>]+)>$from}s)
			and $from_conv = $1;
		($response->content =~ m{<option value=([^>]+)>$to}s)
			and $to_conv = $1;
		if( ! $from_conv or ! $to_conv ) {
			return ("cannot convert " . ($from_conv ? $to : $from));
		} elsif( $to_conv eq '---' or $from_conv eq '---' ) {
			return "no data available";
		}
		my $returned = $amount * $from_conv / $to_conv;
		return sprintf( "%.4f", $returned );
	} else { return "cannot reach site" }
}


sub do_cc {
	$_ = $_[0];
	return 'bad search term' if /[^\w -]/;
	return do_country($_)
	#return '(use the :country function next time) ' . do_country($_)
		 if /^\w\w$/;
	s/^\s*|\s*$//go;
	s/\s{2,}/ /go;
	s/\s(\w)/ \u$1/go;
	$_ = ucfirst;
	my $ret = get_cc( 1, $_ );
	return $ret ? "$_: $ret" : "$_: not found";
}
	

sub do_country {
	$_ = $_[0];
	return do_cc($_) if not /^\w\w$/;
	#return '(use the :cc function next time) ' . do_cc($_) if not /^\w\w$/;
	$_ = uc;
	my $ret = get_cc( 0, $_ );
	return $ret ? "$_: $ret" : "$_: not found";
}


sub get_cc {

	my ($get_cc, $search) = @_;
	$search =~ s/\s+/[\\n\\s\\t]*/go; # the data occasionally has linebreaks
	my $returned;

	my $ua = new LWP::UserAgent;
	my $request = HTTP::Request->new( 'GET',
		'http://www.iana.org/cctld/cctld-whois.htm' );
	my $response = $ua->request( $request );
	if( $response->is_success ) {

		if( $get_cc ) { ($response->content =~
			/\.(\w{2})&nbsp;&nbsp;&#150;&nbsp;&nbsp;$search/si)
			and $returned = uc( $1 ) }
		else { ($response->content =~
			/\.$search&nbsp;&nbsp;&#150;&nbsp;&nbsp;([^<]+)/si)
			and ($returned = $1) =~ s/\s+/ /o }

	}
	return $returned ? $returned : undef;

}


sub do_weather2 {
	my( $city, $country );
	(($city, $country) = $_[0] =~ /^\s*([\w -]+)\s*,\s*(\w\w)\s*$/o)
		or (($city, my $state, $country) = $_[0] =~
			/^\s*([\w -]+)\s*,\s*(\w\w)\s*,\s*(US)\s*$/io)
		or return undef;
	
	if( $country =~ s/US/io/ ) { $country = $state }
	else { return "$country not found"
		unless ($country = get_cc( 0, $country )) }
	#$country = (get_cc( 0, $country ) or $country);

	my $returned;
	my $ua = new LWP::UserAgent;

	$country =~ s/ /+/go;
	my $request = HTTP::Request->new( 'GET',
		'http://www.wunderground.org/cgi-bin/findweather/'
		. 'getForecast?query=' . $city . '%2c+' . $country );
	$country =~ s/\+/ /go;
		
	my $response = $ua->request( $request );
	if( $response->is_success ) {

		# we use extended re's here, so spaces in the search terms
		# must be escaped
		(my $lcity = $city) =~ s/\s/\\s/go;
		(my $lcountry = $country) =~ s/\s/\\s/go;

		# if search matches several locations
		if( $response->content =~ m-$lcity,\s$lcountry</a></td><td>
			([\d.]+).*?</td><td>[^<]*</td><td>[^<]*
			</td><td>([^<]+)-xis )
			{ $returned = "$2, " . c2f2c( 'F', $1 ) . "C/$1F";
				print STDERR '(1)' }
		# if there is only one match
		elsif( $response->content =~ m-$lcity,\s$lcountry</b>
			.*?Temperature.*?<b>([\d.]+).*?
			Conditions.*?<b>([^<]+)-xis )
			{ $returned = "$2, ". c2f2c( 'F', $1 ) . "C/$1F";
				print STDERR '(2)' }

		elsif( $response->content =~ m->$lcity[^<]*
			Forecast</font>
			.*?<tr\s><td>Temperature.*?<b>([\d.]+).*?
			Conditions.*?<b>([^<]+)-xis )
			{ $returned = "$2, " . c2f2c( 'F', $1 ) . "C/$1F";
				print STDERR '(4)' }
			
		else { $returned = "" };
	}

	# sometimes strange things happen, like searching for Montevideo, UY
	# returns the page for Montevideo, MN. Alos for US states. so...

	if( ! $returned ) {
		$country =~ s/ /+/go;
		$request = HTTP::Request->new( 'GET',
		'http://www.wunderground.org/cgi-bin/findweather/'
		. 'getForecast?query=' . $country );
		$country =~ s/\+/ /go;
		
		my $response = $ua->request( $request );
		if( $response->is_success ) {
			(my $lcity = $city) =~ s/\s/\\s/go;
			(my $lcountry = $country) =~ s/\s/\\s/go;

			# if search matches several locations
			if( $response->content =~ m-$lcity</a></td>
				<td>([\d.]+).*?</td><td>[^<]*</td><td>[^<]*
				</td><td>([^<]+)-xis )
				{ $returned = "$2, " . c2f2c( 'F', $1 )
					. "C/$1F"; print STDERR '(3)' }
			elsif( $response->content =~ m->$lcity[^<]*
				Forecast</font>
				.*?<tr\s><td>Temperature.*?<b>([\d.]+).*?
				Conditions.*?<b>([^<]+)-xis )
			{ $returned = "$2, " . c2f2c( 'F', $1 ) . "C/$1F";
				print STDERR '(4)' }
		}
	}

	return $returned ? "$city, $country: $returned" : "no data for"
		. " $city, $country";
}




sub do_whatis () {
	$ENV{PATH} = '';
	$_ = $_[0];
	if( /[^\w-]/o ) { return "lam0r: nothing appropriate" }
	else {
		my $whatis = `/usr/bin/whatis $_`;
		$whatis =~ s/\s{2,}/  /og;
		return $whatis;
	}
}


sub c2f2c {
	my( $from, $temp ) = @_;
	if( $from eq 'C' ) { return sprintf( '%.1f', (9/5 * $temp) + 32 ) }
	else { return sprintf( '%.1f', ($temp - 32) * 5/9 ) }
}


sub do_temp () {
	(my ($from, $from_conv) = $_[0] =~ /\s*([-+]?\d+(?:\.\d+)?)\s*(C|F)\s*/oxi)
		or return ' :how temp';
	$from_conv = uc( $from_conv );
	if( $from_conv eq 'C' ) {
		return sprintf( '%.1fC = %sF', $from,
				c2f2c( $from_conv, $from ));
	} elsif( $from_conv eq 'F' ) {
		return sprintf( '%.1fF = %sC', $from,
				c2f2c( $from_conv, $from ));
	} else { return undef }
}


sub do_ip2int {
	$_ = shift @_;
	$_ =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ or return 'that isn\'t a dotted quad ip address';
	return $1*2**24 + $2*2**16 + $3*2**8 + $4;
}


#sub re_validate {
#	$_ = shift @_;
#	/\?\{/
