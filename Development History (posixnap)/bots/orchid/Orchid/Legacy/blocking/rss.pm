# LotR++ for this one
# minor mods by lenzo@cs.cmu.edu

# to be fixed eventually

use strict;
use warnings;

use LWP::UserAgent;
use XML::RSS;
use HTTP::Request::Common qw{ GET };

our %feeds = (
	pirate	=> 'http://downlode.org/perl/rss/people/pirate.cgi',
	zim			=> 'http://foxden.org/zim/zim.rss',
	gir			=> 'http://foxden.org/zim/gir.rss',
	jerkit	=> 'http://www.phreeow.net/cgi-bin/jerkme.rss',
);

# set up the yahoo feeds
our %ynewsfeeds = map { 
	my ($key) = $_;
	$key =~ s/\s+//g;
	$key = lc $key;
	$key => "http://rss.news.yahoo.com/rss/$key";
} (
	'Top Stories', 'World', 'Business', 'Technology', 'Politics',
	'Sports', 'Entertainment', 'Health', 'Oddly Enough', 'Most Emailed',
	'Highest Rated', 'Most Viewed' 
); 

sub do_eet {
	my ($thischan, $thisuser, $thismsg) = (@_);
	next unless $thismsg =~ /^:/;
	my ($command) = $thismsg =~ /^:(\S+)/;
	my $feed = $feeds{ $command } || $ynewsfeeds{ $command };
	if ($feed) {
		get_headlines( $feed, $thischan, $thisuser, $thismsg );
	}
	else {
		return;
	}
}

sub public { do_eet( @_ ) }
sub private { do_eet( @_ ) }

# this is a really ugly sub/hack. you can be my best friend if you
# want to adopt it and clean it up to fit the rest of the api.
sub get_headlines {
  my ($rdf_loc, $thischan, $thisuser, $thismsg) = @_;

  # to keep people from trying any funny business.
  utility::spew( $thischan, $thisuser, "error: no location stored for $rdf_loc" ) 
		unless $rdf_loc;
  utility::spew( $thischan, $thisuser, "I only like http:// URLs" )
		unless $rdf_loc =~ m{^http://.*?$};

  my $ua = LWP::UserAgent->new;
  $ua->agent("Petunia [ http://minotaur.posixnap.net/cgi-bin/cvsweb.cgi/bots/petunia_merge/ ]");
  my $result = $ua->request(GET($rdf_loc,  )); # add any more headers?

  unless( $result->is_success ) {
    my $status = $result->status_line;
    $status =~ s/\s+/ /s;
    utility::spew( $thischan, $thisuser,  "error: $rdf_loc gave an HTTP error: $status" )
    	if $status =~ m/^[\x20-\x7e]{2,200}$/s;
  }

  my $content_ref = $result->content_ref;
  unless( defined $$content_ref and length $$content_ref ) {
    utility::spew( $thischan, $thisuser, "error: $rdf_loc returned null content" );
  }

  my $rss = XML::RSS->new;
  eval { $rss->parse( $$content_ref ); };

  if ($@) {
    my $status = $@;
    $status =~ s/\s+/ /s;
    $status =~ s/ at \S+\.pm line .+$//s; # nix module note
    utiliy::spew( $thischan, $thisuser, "error: $rdf_loc gave an RSS-parsing error: $status" )
    	if $status =~ m/^[\x20-\x7e]{2,200}$/s;
  }
  
  my $return = '';

  foreach my $item (@{$rss->{"items"}}) {
    $return .= $item->{"title"} . "; ";
    last if length($return) > 300;
  }

  $return =~ s/; $//;
  $return =~ s/\s+/ /; # smash whitespace

  utility::spew( $thischan, $thisuser, "error: $rdf_loc returned no visible content" )
  	unless $return =~ m/[^ ;]/;

  utility::spew( $thischan, $thisuser, encoding_sanitize($return) );
};

sub encoding_sanitize {
  use utf8 ();
  # On pre-utf8 perls, just make this:   sub encoding_sanitize {$_[0]}

  my $r = $_[0];

  # Make Win-1251 into proper Latin-1...
  $r =~ s/~D/,,/g;
  $r =~ s/~E/.../g;
  $r =~ s/~L/OE/g;
  $r =~ s/~Y/tm/g;
  $r =~ s/~\\/oe/g;
  $r =~ 
   s[~@~A~B~C~F~G~H~I~J~K~M~N~O~P~Q~R~S~T~U--~X~Z~[~]~^~_]
    [e?,F**^%S<?Z?Z''""*--~s>?zY]g
  ;

  return $r if $r !~ m/^[\x00-\x7f]+$/ # usual case: a normal US-ASCII string
  ;

  # Otherwise filter it into at Latin-1 niceness:
  my $x = # downgrade to non-utf8
    join '',
      map chr(($_ > 255) ? 0xA4 : $_),
        unpack 'U*', $r;
         # xA4 = the splat-currency character, which I'm here using as a nix.

  $x =~ s/\xA4{4,}/\xA4\xA4\xA4\xA4/g; # avoid having huge strings of nixes
  return $x;
}

1;
