code
# give the user a weather report.
sub weather_report {
  my ($thisuser, $thischan, $thismsg) = (@_);
  return "weather_report" if @_ == 0;
  return unless $thismsg =~ /^:wr /;
  my ($city, $state) = $thismsg =~ /^:wr\s+([^,]+),\s+(\S+)/;
  $city = lc $city;
  $state = lc $state;

  use Geo::WeatherNOAA;
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
      $weather =~ s/&deg;/°/g;
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
  my $weather = print_current($city, $state);
  if ($weather =~ "No data available") {
    $weather = attempt_funny_weather($city, $state);
    lineitemveto($weather);
    return 1;
  }
  else {
    $weather =~ s/^Error.*/No Data for $city, $state/;
    $weather =~ s/&deg;/°/g;
    lineitemveto($weather);
    return 1;
  }
  return 0;

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
        my @fields = split /\s+/, $line;
        if (@fields == 9) {
          # Yay, we successfully parsed alaska
          if ($fields[0] =~ /^[A-Z]{5}/) {
            # this is an unsafe assumption, but there isnt much else we can do
            # something like Nome, Virginia would catch the alaska processing.
            # looks like we parsed a two-word virginia city
          }
          else {
            # we're still parsing alaska
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
        return $output;
      }
    }
  }
}

(1 row)
