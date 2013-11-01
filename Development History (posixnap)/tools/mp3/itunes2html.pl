#!/usr/bin/perl -w
use strict; $|++; use Getopt::Long; my %options;
###############################################################################
# creates a list of your mp3 albums, based on itunes XML. I assume things     #
# about how you id3 your collection, as well as how you want the output.      #
# the actual expectations are explained in the output, available online:      #
# http://www.disobey.com/detergent/lists/albums.html - fun for everyone!      #
# this makes a really large, obscene memory structure before printing.        #
# modified: 2003-02-03, morbus@disobey.com, lemme know if you use/modify.     #
#                                                                             #
# to run this script, use the terminal to enter the following command         #
# (your library is normally at "~Music/iTunes/iTunes Music Library.xml"):     #
#                                                                             #
#     perl itunes2html.txt "/path/to/iTunes Music Library.xml"                #
#                                                                             #
# more options on the usage of itunes2html can be seen by looking a bit       #
# lower below (in the actual code), or by issuing the following command:      #
#                                                                             #
#     perl itunes2html.txt --help                                             #
###############################################################################
# latest changes (2003-02-03):                                                #
#   - stylesheet built in, not off of disobey.com.                            #
#   - spelling and wording corrections.                                       #
#   - help dialog and command line options.                                   #
#   - can process songs that are missing track or disc numbers (at            #
#     the expense of losing some display features. fix 'em, dammit!).         #
#   - we spit out HTML now, not XHTML.                                        #
#   - sorting comments are removed from output, making page size smaller.     #
#   - HTTP::Date is now optional (error is spit, but progress continues).     #
#                                                                             #
# features i may add when i'm bored:                                          #
#   - amazon/cddb search lines when no Comment URL found.                     #
#   - ability to create HTTP links for downloading (ala iCommune).            #
#                                                                             #
# biggest bug (that I probably won't fix):                                    #
#   - since we sort by artists, we falsely assume that only one artist        #
#     can produce an album. thus, an album that has multiple artists that     #
#     has NOT been designated as "Various Artists" will severely alter        #
#     the listings (one entry for each artist per that album), as well as     #
#     the total album count. supposedly, "part of a compilation" should       #
#     be used to work around this, but that would require a restructuring     #
#     of our in-memory data structure, and in other words, force a rewrite    #
#     unless we think of a cute way around it (an array of compilations?)     #
###############################################################################

# no modification/reading below this line is necessary.
# dedicated to all those shareware people that charge
# money for relatively mindless tasks such as this.

###############################################################################
# our options matrix. see the comments here, or a -h on the command line.     #
###############################################################################
GetOptions(\%options, 'help|h|?',             # print out our help dialog.
                      'missingdiscnumbers',   # ignore missing disc numbers.
                      'missingtracknumbers',  # ignore missing track numbers.
);

###############################################################################
# spit out our help if necessary (either, it's been requested via the command #
# line, or no one filled in the path to the itunes library xml file.          #
###############################################################################
if ($options{help} or !$ARGV[0]) { print <<"END_OF_HELP";
itunes2html - converts your music library into an html page.
Usage: perl itunes2html.txt [OPTION] [FILE]...
 (typically "~/Music/Itunes/iTunes Music Library.xml")

  -h, -?, --help         Display this message and exit.

  --missingdiscnumbers   If you're tracks aren't labeled with the "disc # of #"
                         id3 tag, then they're normally ignored by itunes2html.
                         If you'd like itunes2html to accept tracks with this
                         missing information, use this flag. Turning on this
                         option will ignore "disc # of #" for ALL YOUR TRACKS
                         (which will reduce the information displayed).

  --missingtracknumbers  Tracks that don't have "track # of #" id3 tags are
                         normally ignored for not having "proper" id3 info.
                         If you'd like itunes2html to accept tracks without
                         track numbers, add this flag to your command
                         line. Turning on this option will ignore "track
                         # of #" for ALL YOUR TRACKS (which will reduce
                         the information displayed).

If you'd like certain albums or tracks not to be listed in the export,
add a character like | to the beginning of the track's album name.

Tracks that don't have artist, album, track number, or disc number id3
tags are spit to STDERR so that you can fix them when you have copius
amounts of spare time. These warnings can not be shut off (ha!).

Mail bug reports and suggestions to <morbus\@disobey.com>.
END_OF_HELP
exit ;}

###############################################################################
# check to see if the user has the non-default HTTP:: Date installed.         #
# if not, give an error about it and continue with no date checking.          #
###############################################################################
eval("use HTTP::Date;");
my $check_dates = 1; if ($@) {
   print STDERR "ERROR: HTTP::Date is not installed - ".
                "skipping \"last 30 days\" feature.\n";
   $check_dates = 0;
}

# get the path of our XML file and open the bad boy.
my $file = $ARGV[0]; die "file [$file] does not exist\n" unless -e $file;
open (XML, "<$file") or die "file [$file] couldn't be opened: $!";

###############################################################################
# process each line of our XML file.                                          #
###############################################################################
my ($albums, $total_albums, $total_tracks);
$/ = "<dict>"; # now, start looping.
while (<XML>) {

   next unless /Artist/i; # skips starting <dict> instances.
   s/[\t\r\n\f]//g; # remove all tabs, newlines, and so forth.

   # used in our data structure.
   my ($artist)       = $_ =~ m!<key>Artist</key><string>(.*?)</string>!;
   my ($album)        = $_ =~ m!<key>Album</key><string>(.*?)</string>!;
   my ($track_number) = $_ =~ m!<key>Track Number</key><integer>(.*?)</integer>!;
   my ($disc_number)  = $_ =~ m!<key>Disc Number</key><integer>(.*?)</integer>!;

   # skip !alphanumeric albums.
   next if ($album !~ /^\w/);

   # spit an error if some of this stuff is missing.
   unless ($artist and $album and $track_number and $disc_number) {

      # there's probably a simpler way of doing this.
      my @missing; # a list of missing fields per track.
      push(@missing, "artist") unless defined($artist);
      push(@missing, "album") unless defined($album);
      push(@missing, "track_number") unless defined($track_number);
      push(@missing, "disc_number") unless defined($disc_number);

      # print out the error message to STDERR. boring code here.
      my ($file)  = $_ =~ m!<key>Location</key><string>(.*?)</string>!;
      $file =~ s!(file://|localhost|Volumes)!!gi; # garbage for removal.
      $file =~ s/%20/ /g; # quickie URL encoding to happier reading.
      print STDERR "Missing ", join(", ", @missing), " for $file.\n";
      next; # well, that was certainly boring. who rules?! not me.
   }

   # check our command line options. if either have been set,
   # then we use dummy track and disc numbers for this track.
   # this is regardless if some of the tracks have proper
   # information (hey... fix 'em or get crap, buddy). we
   # do this after we spit out an error to STDERR (above).
   if ($options{missingdiscnumbers}) { $disc_number = 1; }
   if ($options{missingtracknumbers}) { $track_number = 1; }

   # and continue on with some extra information.
   my ($disc_count) = $_ =~ m!<key>Disc Count</key><integer>(.*?)</integer>!;
   $albums->{$artist}{$album}{"Disc Count"} = $disc_count;

   # and now the rest of the fields in one fell swoop.
   $albums->{$artist}{$album}{$disc_number}{$track_number}{$1} = $3
     while (m!<key>(.*?)</key><(integer|string|date)>(.*?)</(integer|string|date)>!g);

$total_tracks++; } close(XML);

###############################################################################
# create aggregate information for the album (totals, globals, etc.)          #
###############################################################################
foreach my $artist ( keys %{$albums} ) {
   foreach my $album ( keys %{$albums->{$artist}} ) {

      # get track counts.
      my $album_total_tracks; # all tracks, regardless of disc.
      for (my $i = 1; $i <= $albums->{$artist}{$album}{"Disc Count"}; $i++) {
         foreach my $track ( sort keys %{$albums->{$artist}{$album}{$i}} ) {
            $album_total_tracks++; # increment the track counter.

            # has this track been played before? if so, add to the count.
            if ($albums->{$artist}{$album}{$i}{$track}{"Play Count"}) {
               my $play_count = $albums->{$artist}{$album}{$i}{$track}{"Play Count"};
               $albums->{$artist}{$album}{"Play Count"} += $play_count;
            }

            # other global values. we set them here to make our outputting code smaller.
            # we really should set these only if they're not set already. less work.
            $albums->{$artist}{$album}{Comments} = $albums->{$artist}{$album}{$i}{$track}{Comments} || undef;
            $albums->{$artist}{$album}{Genre} = $albums->{$artist}{$album}{$i}{$track}{Genre} || "(blank)";
            $albums->{$artist}{$album}{Year} = $albums->{$artist}{$album}{$i}{$track}{Year} || "????";
            $albums->{$artist}{$album}{"Date Added"} = $albums->{$artist}{$album}{$i}{$track}{"Date Added"};
            $albums->{$artist}{$album}{"Play Count"} |= 0; # if it's not defined, zero it out.
         }
      }

      # finalize our incrementers and totals.
      $albums->{$artist}{$album}{"Track Count"} = $album_total_tracks; $total_albums++;
   }
}

###############################################################################
# now, pretty print everything out. i want one script, so no templating.      #
###############################################################################

my $updated = localtime(time);
print <<EVIL_HEREDOC_HEADER_OF_ORMS_BY_GORE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>Albums in MP3 Format ($updated)</title>
  <style type="text/css"><!--
    p { margin-left: 0.35em; }
    th, tr, td { font-size: 12px; }
    .old { background-color: #fff; }
    .new { background-color: #ffc; }
    table { margin-left: 5px; margin-right: 5px; }
    ul li { margin-top: 0em; margin-right: 2.5em; }
    body { margin: 1em; font-family: arial, sans-serif; }
    h1, h2 { background-color: transparent; color: #001080;
             font-family: tahoma, sans-serif; }
  //--></style>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>

<h1>Albums in MP3 Format</h1>
<p>Got a list of your own or have questions? Send email to &lt;<a
href="mailto:morbus\@disobey.com">morbus\@disobey.com</a>&gt;. The
below contains listings for <strong>$total_albums albums, comprising
$total_tracks total tracks</strong> and was last generated $updated.
It was <a href="http://www.disobey.com/d/perl/itunes2html.txt">created
by a Perl script from Morbus Iff</a> that reads the exported XML provided
by <a href="http://www.apple.com/itunes/">Apple's iTunes</a>. This
automation is only possible because I'm insanely ana... pedantic about the
quality of my id3 tags. Some assumptions (which can be disabled 
<a href="http://www.disobey.com/d/perl/itunes2html.txt">by the script</a>)
have been made:</p>

<ul><li>All tracks have <em>Title</em>, <em>Artist</em>, <em>Album</em>, <em>Year</em>, and <em>Track # of #</em>.</li>
<li>All tracks have a source URL in their <em>Comments</em> field.</li>
<li>All albums (and tracks) have <em>Disc # of #</em> information.</li>
<li>I use only three genres: <em>(blank)</em>, <em>Soundtrack</em>, and <em>Game</em>.<br />Genre is a subjective opinion, so I try to stick with the facts.</li>
<li>Albums that don't start with an alphanumeric aren't shown.</li>
<li>These are full albums only - no singles.</li></ul>
EVIL_HEREDOC_HEADER_OF_ORMS_BY_GORE

# if HTTP::Date is installed, spit out our color information.
if ($check_dates) { print "<p class=\"new\">Albums with this background color have been added in the past 30 days.</p>"; }

# now, go through each artist and album. we actually add all this stuff
# to genre specific arrays first, since, in my case, genre is more in line
# with "category" (I prefer only three genres, defined above in the HTML).
my %genres; foreach my $artist (sort keys %{$albums}) {

   # we don't sort here - we'll sort on printout only. this
   # gives us a chance to sort the items based on genre (I
   # prefer not to see artists for both Game and Soundtracks).
   foreach my $album (keys %{$albums->{$artist}}) {
      my $current_genre = $albums->{$artist}{$album}{Genre};
      $genres{$current_genre} = [] unless defined $genres{$current_genre};

      # determine the album/artist labelling. if this is
      # "Game" or "Soundtrack", don't show the artist.
      my $name; if ($current_genre =~ /(Game|Soundtrack)/) { $name = $album; } else { $name = "$artist-$album"; }
      my $year = $albums->{$artist}{$album}{Year}; my $play_count = $albums->{$artist}{$album}{"Play Count"};
      my $disc_count = $albums->{$artist}{$album}{"Disc Count"}; # shorter;
      my $track_count = $albums->{$artist}{$album}{"Track Count"}; # shorter;

      # get our comment string and make it a URL. if it's an Amazon
      # URL, make it an affiliate clickthrough. we, of course, only do
      # this if there's a Comments string to be had. bad id3er!
      my $link; if (defined $albums->{$artist}{$album}{Comments}) { 
         $albums->{$artist}{$album}{Comments} =~ s!(http://[^\s<]+)!$1!i;
         if ($albums->{$artist}{$album}{Comments} =~ /amazon.com/)
            { $albums->{$artist}{$album}{Comments} .= "disobeycom"; }
         $link = $albums->{$artist}{$album}{Comments}; # shorter.
         undef $link unless $link =~ /^http/; # if link isn't a url.
      } # this should really be in id3's URL, but iTunes doesn't support it.

      # create $linked_name with our album name if a URL was found.
      my $linked_name; if (defined $link) { $linked_name = "<a href=\"$link\">$name</a>"; }

      # when was this album added? if it's within the
      # past 30 days, add a class="new" to our <tr> tag.
      my $class = "old"; # turns to "new" if, indeed, it's new.
      if ($check_dates) { # only do this if HTTP::Date is installed.
         my $current_seconds = time; my $added_seconds = str2time($albums->{$artist}{$album}{"Date Added"});
         if ( ($current_seconds - $added_seconds) < 2592000) { $class = "new"; }
      } # who wishes to rub the back of Morbus Iff?!!

      # now push to our genre array (which is sorted later).
      # we do a really stupid cheating comment so that we can
      # sort the entries based on the $name, not something 
      # like "$artist-$album" (see comments above, slacker).
      push @{$genres{$current_genre}}, "<!-- $name --><tr class=\"$class\">" .
                                       "<td width=\"600\">" . ($linked_name || $name) . "</td>" .
                                       "<td align=\"center\">$year</td>" .
                                       (defined($options{missingdiscnumbers}) ? "" : "<td align=\"center\">$disc_count</td>") .
                                       (defined($options{missingtracknumbers}) ? "" : "<td align=\"center\">$track_count</td>") .
                                       (defined($options{missingtracknumbers}) ? "" : "<td align=\"center\">$play_count</td>") .
                                       "</tr>\n"; # i am master of 'leet whitespace!
   }
}

# now, print out each genre.
foreach my $genre (sort keys %genres) {

   # create a giant string for display. we also remove
   # any comments we may have added for our artist/
   # album sorting, which reduces page size.
   my $output = join ("", map { s/<!-- .* -->//; $_; } sort @{$genres{$genre}});

   # print this crazy chicken.
   print "<h2>$genre:</h2>\n"; # the start of a beautiful rela...
   print "<table border=\"1\" cellpadding=\"2\" width=\"100%\">\n";
   print "<tr><th>Album</th><th>Year</th>" . 
          (defined $options{missingdiscnumbers} ? "" : "<th>Discs</th>") .
          (defined $options{missingtracknumbers} ? "" : "<th>Track Count</th>") .
          (defined($options{missingtracknumbers}) ? "" : "<th>Tracks Played</th>") . "</tr>\n";
   print "$output\n</table>\n"; # i hate you! never talk to me again!
} print "</body>\n</html>";

