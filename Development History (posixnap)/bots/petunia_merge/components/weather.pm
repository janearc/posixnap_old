##
## weather.pm
##
## posixnap has at least four different methods for getting weather reports
## from, seemingly, all over the globe. this module globs all of them together
## and is driven by the pelvis interface.
##
## please see credits file.
##

## Please note that Tyler is working on this. If you make changes I'll need
## to merge it. Please let me know. Otherwise we might end up with a fork
## in your head.

use constant UNSPECIFIED_ERROR => 5;
use constant INTARWEB_ERROR => 6;

use constant SUCCESS => 255;

use warnings;

my (@spewn, $city, $state, $country);

sub private {
	my ($thischan, $thisuser, $thismsg) = @_;
	unless ($thismsg =~ /^:(wr|weather|weather2)/ ) { return; }
	if ($thismsg =~ /wr/) { 
		$thismsg =~ s/^:wr\s+(.*?)$/$1/; 
		@spewn = do_wr( $thismsg ); 
		my @spewen = split ( /\n/, $spewn[2] );
		foreach (@spewen) {
			utility::spew($thischan, $thisuser, "$_");
		}
		return;
	}
	if ($thismsg =~ /weather/) {
		$thismsg =~ s/^:\w+\s+(.*?)$/$1/; 
		@spewn = do_weather( $thismsg );
		unless ( $spewn[0] =~ /data/ ) {	
			utility::spew($thischan, $thisuser, 
				"Weather in $spewn[0], $spewn[1]: $spewn[2]");
			return;
		}
		utility::spew($thischan, $thisuser, "I'm sorry, $spewn[0]");
	}
}
sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
	unless ($thismsg =~ /^:(wr|weather|weather2)/ ) { return; }
	if ($thismsg =~ /wr/) { 
		$thismsg =~ s/^:wr\s+(.*?)$/$1/; 
		@spewn = do_wr( $thismsg ); 
		my @spewen = split ( /\n/, $spewn[2] );
		foreach (@spewen) {
			utility::spew($thischan, $thisuser, "$_");
		}
		return;
	}
	if ($thismsg =~ /weather/) {
		$thismsg =~ s/^:\w+\s+(.*?)$/$1/; 
		@spewn = do_weather( $thismsg );
		unless ( $spewn[0] =~ /data/ || $spewn[0] > 4 ) {	
			utility::spew($thischan, $thisuser, 
				"Weather in $spewn[0], $spewn[1]: $spewn[2]");
			return;
		}
		$spewn[0] = qq/no data found for $thismsg/;
		utility::spew($thischan, $thisuser, "I'm sorry, $spewn[0]");
	}
}

sub do_weather {
	
	my $thismsg = shift;

	my ($city, $prov, $country);

	($city, $prov, $country) = $thismsg =~ m!
		^\s*([[:alpha:]\s]+[[:alpha:]])\s*,
	  \s*([[:alpha:]]{2})\s*,
	  \s*([[:alpha:]]{2})\s*$
	!ox;
	if (not ($city, $prov, $country)) {
		($city, $country) = $thismsg =~ m!
			/^([[:alpha:]\s]+[[:alpha:]])\s*,
			\s*([[:alpha:]]{2})\s*$
		!ox;
	}

	if (not ($city, $country)) {
		# still not matching anything in the regex
		return UNSPECIFIED_ERROR;
	}
	unless ($city, $prov, $country) { return undef; }
	
	# $weather is what we will eventually be returning after we grok all
	# this icky html.
	my $weather;

	$prov = uc $prov;
	$country = uc $country;

	# this uppercases the first letters of each word.
	$city = ucfirst $city;
	$city =~ s/\s+(\w)/ \u$1/g;

	# we set up the LWP agent here, and grab $request's from it later on in their
	# own scopes.
	my $ua = new LWP::UserAgent;

	# canadia.
	if ($country eq 'CA') {

		# set some spiffy canuck weather information
		my %provinces = ( 
					BC => 'British+Columbia',
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
		$city =~ y/ /+/;
		my $url = "http://weather.ec.gc.ca/wcgi-bin/forecast/"
			. "forecast.cgi?city=" . $city . "&province="
			. $prov;

		# get rid of the +s for output
		$city =~ y/+/ /; 

		# set up all our web objects. yay intarweb.
		my $request = HTTP::Request -> new( 'GET', $url );
		my $response = $ua -> request($request);
		my ($cond, $temp);

		if ( $response -> is_success() ) {
			($cond, $temp) = $response->content =~
				m!<FONT\sSIZE=-1>.<CENTER><B>([^<]+).+?
				  Temperature:.+?<B>([^<]+)</B>!osx;
			if ($temp) { $weather = $cond . ", " . $temp };
		}
		else {
			utility::debug( "do_weather: ack! could not retreive $url. [canuck weather]" );
			return INTARWEB_ERROR;
		}
	
	} # canada weather
	else {

		my $url;

		if( $country eq 'US' ) { 
			$url = "http://weather.noaa.gov/weather/" . $prov . "_cc_us.html";
		}
		else {
			$url = "http://weather.noaa.gov/weather/" . $country . "_cc.html" 
		}

		my $request = HTTP::Request -> new( 'GET', $url );
		my $response = $ua -> request($request);
		if ($response -> is_success) {
			my $code;
			# should maybe nest another if?
			if ( my ($code) = $response -> content() =~ m!<OPTION\sVALUE="(....)">\s$city!is ) {
			$url = "http://weather.noaa.gov/cgi-bin/call_currwx.pl"
			       . "?cccc=" . $code;
			$request = HTTP::Request->new( 'GET', $url );
			$response = $ua->request( $request );
			if ($response->is_success) {
				my ($cond, $temp) = $response -> content() =~ m!
					Sky\sconditions\s</FONT></FONT></B>
					</TD>..<TD><FONT\sFACE="Arial,Helvetica">..(.+?)..</FONT>.*?
					Temperature\s</FONT></FONT></B></TD>..<TD>
					<FONT\sFACE="Arial,Helvetica">..(.+?)..</FONT>
				!osx;
				$weather = $cond ? $cond.", ".$temp
						 : $temp
			}
			else {
				utility::debug( "do_weather: could not retreive $url" );
				return INTARWEB_ERROR;
			}
		} 
		else { 
			return "no data for $city";
		}
	}
	

	} # prepare to return this shit.
	utility::debug("getting ready to return $city, $country, $weather");
	my @returns;
	if ($weather) {
		@returns = ( $city, $country, $weather );
	}
	else {
		@returns = ( $city, $country, "No data found." );
	}
	return @returns;
}

sub do_weather2 {
	return ("NOT", "IMPLEMENTED", "YET");
}

sub do_wr {
	my $thismsg = shift;
	($city, $state) = $thismsg =~ m/([^,]+),\s+(\S+)/;
	
	$state =~ y/,//d;

	unless  ($city && $state) {
		# still not matching anything in the regex
		return UNSPECIFIED_ERROR;
	}
	$city = lc $city;
	$state = lc $state;
	
	use Geo::WeatherNOAA;

	## Since the new framework uses the former form of DBH I am inserting Alex's
	## code commented. Alex can come through and fix the POE framework on this
	## part.

=cut
	my ($kludged) = select_one(qq{
	select count(kludge_city) from weather_kludges
      		where city='$city' and state='$state'
  		});
  	if ($kludged) {
    		# we have found that NOAA does not store information
    		# for this city so we take a kludge out of the database
    		# which we then use to query noaa with.
    		my ($kCity, $kState);
    		my $rowRef = $dbh -> selectrow_arrayref(qq{
      		select kludge_city, kludge_state from weather_kludges
        		where city='$city' and state='$state'
    });
    if (ref $rowRef) {
      my ($kCity, $kState) = @{ $rowRef };
      $kCity =~ s/\s+$//;
      my $weather = print_current($kCity, $kState);
      $weather =~ s/&deg;/Â°/g;
      if ($weather =~ "No data available") {
        $weather = attempt_funny_weather($kCity, $kState);
        lineitemveto($weather);
        return 1;
	}
      else {
        lineitemveto($weather);
        return 1;
      }
    }
    else {
      $nap -> public_message("kludge failed for $city, $state");
      return 1;
    }
  }
=cut
  
	## Begin NOAA code.
	my $weather = print_current($city, $state);
		if ($weather =~ "No data available") {
			$weather = attempt_funny_weather($city, $state);
			return ($city, $state, $weather);
		}
		else {
			$weather =~ s/^Error.*/No Data for $city, $state/;
			$weather =~ s/&deg;/°/g;
			return ( $city, $state, $weather );
		}
return 0;
	
}

sub attempt_funny_weather {
   my $urlbase = "http://iwin.nws.noaa.gov/iwin";
    my ($city, $state) = (@_);
    my $url = "$urlbase/$state/hourly.html";
    use LWP::Simple;
    my @page = split /\n|\r\n|\n\r/, get($url);
   
    PARSING: foreach my $line (@page) {
      my %Hweather;
      next if $line =~ /Not Available/i;
      $line =~ s/No Report/NoReport/i;
      if ($line =~ /$city/i) {
	utility::debug("found $city");
        my @fields = split /\s+/, $line;
        if (@fields == 9) {
          # Yay, we successfully parsed alaska
          if ($fields[0] =~ /^\w{4}/) {	

            # this is an unsafe assumption, but there isnt much else we can do
            # something like Nome, Virginia would catch the alaska processing.
            # looks like we parsed a two-word virginia city
            ( $Hweather{code},
              $Hweather{city},
              $Hweather{weather},
              $Hweather{temp},
              $Hweather{humidity},
              $Hweather{wind},
              $Hweather{pressure},
              $Hweather{windchill},
              $Hweather{visibility}, ) = @fields;
          }
        }
        elsif (@fields == 8) {
          # Yay, we successfully parsed virginia
        }
        elsif (@fields == 10) {
          # here we probably parsed King Salmon, alaska or somesuch
        }
      }

      if (scalar keys %Hweather != 9) {
        next PARSING;
	}

      my $wind = format_wind($Hweather{wind});

      my $output;
      $output = "Conditions at $city, $state were ";
      $output .= $Hweather{weather}." at ";
      if ($Hweather{temp} == $Hweather{windchill}) {
        $output .= "$Hweather{temp} F ";
      }
      else {
        $output .= "$Hweather{temp} F ($Hweather{windchill} F with windchill) ";
      }
      $output .= "with wind $wind. ";
      $output .= "Humidity was $Hweather{humidity}\% ";
      $output .= "and barometric pressure was $Hweather{pressure} inches.";
	utility::debug("returning $output");
      return $output;
      last;
      sub format_wind {
        my $wind = shift;
        return $wind if $wind =~ /calm/i;
        my %compass = ( N => 'north', S => 'south', E => 'east', W => 'west' );
        my ($dir, $speed, $gust, $gspeed) = $wind =~ /([A-Z])(\d+)(G)?(\d+)?/;

        my $output = $compass{$dir};
        $output .= " at $speed mph";
        if ($gust) {
          $output .= " with gusts up to $gspeed mph";
        }
	utility::debug(" Returning: $output");
        return $output;
      }
    }

}



