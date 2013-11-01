use strict;
use warnings;
use Socket;
use LWP;

# salvy

my $url = q{http://www.geobytes.com/IpLocator.htm?GetLocation};
my $post = q{cid=0&c=&Template=iplocator.htm&ipaddress=};
my $ua = q{Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.3) Gecko/20030312};

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser,
		":ipmap <hostname|ip> - Will attempt to locate the Hostname|ip" . 
			" to a geographical address." );
}

sub ipmap {
    my ($thischan, $thisuser, $thismsg) = (@_);
    my ($ip) = $thismsg =~ /^:ipmap\s+(\S*)/;
    if ( $thismsg =~ /^:ipmap/ ) {
	utility::spew( $thischan, $thisuser, "try again, dumbass." ) unless $ip;
	  unless (length(inet_aton($ip)) eq 4) { 
	      utility::spew($thischan, $thisuser, "Invalid IP address."); 
	      return; 
	  }
	  my $ua = LWP::UserAgent->new;
	  $ua->agent("PetuniaAPI/0.1");
	  my $req = HTTP::Request->new(POST => $url);
	  $req->content_type('application/x-www-form-urlencoded');
	  $req->content($post . $ip);
	  my $res = $ua->request($req);

	  my %fart = map { /^\s+\<td\s+align\=\"right\"\>(\w+|\w+\s+\w+)\s+\<.*?value\=\"(.*?)\".*$/i 
			       ? ( $1 => $2 ) : () } split ( /\n/ , $res->content) if ($res->is_success);
	  if ($fart{City} && $fart{Region} && $fart{Country} && $fart{Latitude} &&
	      $fart{Longitude} && $fart{TimeZone} && $fart{'Currency Code'} ) {
	      utility::spew( $thischan, $thisuser, "$fart{City}, $fart{Region}, $fart{Country} " . 
			 "| Lat: $fart{Latitude} Lon: $fart{Longitude} | UTC: $fart{TimeZone} " .
			 "| Currency: $fart{'Currency Code'}" );
	  } else {
	      utility::spew( $thischan, $thisuser, "Invalid IP address, or cannot locate. Try again later.");
	  }
      }
}
sub public {
    ipmap( @_ );
    }
sub private {
    ipmap( @_ );
}
