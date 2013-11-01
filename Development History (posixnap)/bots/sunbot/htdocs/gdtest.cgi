#!/usr/local/bin/perl

use warnings;
use strict;
use GD::Graph::pie;
use GD::Graph::bars;
use CGI qw{:standard};
use CGI::Carp qw{fatalsToBrowser};
use DBI;
use File::Slurp;

qx{ rm -f /usr/local/apache/htdocs/*.png };

$|++;

my $dbh = DBI->connect("dbi:Pg:dbname=sys_monitor;host=172.17.54.254", "tyler")
	or die "ACK! Couldnt connect to DB! $!";
my $host;
$host = $ENV{QUERY_STRING} unless ($host = $ENV{QUERY_STRING} =~ m/^server=(.*)$/);

my ($fart, @load, $sqlquery);

if (param()) {
	my $constrain++;
	# Construct an alternate sql query.
	if (param('fyear') && param('fmonth')) {
		$sqlquery = " where stamp >= '" . param('fyear') . "-" . param('fmonth') . "-" 
			. param('fday') . " " . param('fhour') . ":" . param('fmin') 
			. "' and stamp <= '" . param('tyear') . "-" . param('tmonth') .
			"-" . param('tday') . " " . param('thour') . ":" . param('tmin') ."'";
	}
}

print header, start_html("System: $host"),
      qq{<meta http-equiv="refresh" content="300">},
      qq{<TABLE width="100%" align="center" valign="center" bgcolor=white >};

print qq{<tr><td colspan=4><center>
	Constrained query: $sqlquery</center></td></tr>} if ($sqlquery);
	
print qq{<tr><td width=15% bgcolor="#fbe249" align="center">
	 <font color="#594fbf" face="Arial, Helvetica, sans-serif">
	 <h1>$host</h1></font></td><td width=70% colspan=2><center>
	 <font face="Arial, Helvetica, sans-serif"><h2>Last stat poll:};

my $sth = $dbh->prepare("select stamp, uptime from $host $sqlquery order by stamp desc limit 1");

$sth->execute();

my @stats = $sth->fetchrow_array;

print qq{ $stats[0]<br>at which $host was up $stats[1].</h2></font></center></td>
<td width=15% bgcolor="#594fbf" align=center><font size=+2 color=white fave="Arial, Helvetica, sans-serif">Powered By<br><img src=/logo_sun_home.gif></font></td></tr>};

print qq{<tr><td colspan=4>}, start_form, 
                    qq{<div align=center>Start query at: Month: },
                    popup_menu(-name=>'fmonth', -values=>['1','2','3','4','5','6','7','8',
                                                          '9','10','11','12']),
                    qq{ Day: },
                    popup_menu(-name=>'fday', -values=>['1','2','3','4','5','6','7','8','9','1
0',
                                                        '11','12','13','14','15','16','17','18',
                                                        '19','20','21','22','23','24','25','26',
                                                        '27','28','29','30','31']),
                    qq{ Year: },
                    popup_menu(-name=>'fyear', -values=>['2002','2003','2004','2005']),
                    qq{ Hour: },
                    popup_menu(-name=>'fhour', -values=>['00','01','02','03','04','05','06','07',
                                                         '08','09','10','11','12','13','14','15',
                                                         '16','17','18','19','20','21','22','23']),
                    qq{ Minute: },
                    popup_menu(-name=>'fmin', -values=>['00','05',
                                                        '10','15',
                                                        '20','25',
                                                        '30',
                                                        '35','40',
                                                        '45',
                                                        '50','55']),
		    qq{</div><div align=center>},
		    qq{End query at Month: },
                    popup_menu(-name=>'tmonth', -values=>['1','2','3','4','5','6','7','8',
                                                          '9','10','11','12']),
                    qq{ Day: },
                    popup_menu(-name=>'tday', -values=>['1','2','3','4','5','6','7','8','9','
10',
                                                        '11','12','13','14','15','16','17','18',
                                                        '19','20','21','22','23','24','25','26',
                                                        '27','28','29','30','31']),
                    qq{ Year: },
                    popup_menu(-name=>'tyear', -values=>['2002','2003','2004','2005']),
                    qq{ Hour: },
                    popup_menu(-name=>'thour', -values=>['0','1','2','3','4','5','6','7','8','9',
                                                         '10','12','13','14','15','16','17','18',
                                                         '19','20','21','22','23']),
                    qq{ Minute: },
                    popup_menu(-name=>'tmin', -values=>['00','05',
                                                        '10','15',
							'20','25',
                                                        '30',
                                                        '35','40',
                                                        '45',
                                                        '50','55']),
		    qq{ }. submit("GO!") . qq{</div>}, end_form, qq{</td></tr>};

$sth = $dbh->prepare("select load,cpu,mem,stamp from $host $sqlquery order by stamp desc limit 200");

$sth->execute();

my (@fart, @cpu, @mem, @stamp);

while (@fart = $sth->fetchrow_array) {
	push @load, shift(@fart);
	push @cpu, shift(@fart);
	push @mem, shift(@fart);
	push @stamp, shift(@fart);
}

my @loads = map { /^(\d+\.\d+).*$/ ? $1 : () } @load;
my @loads2 = map { /^.*\s+(\d+\.\d+)$/ ? $1 : () } @load;
my @usr = map { /^(\d+)\;(\d+)\;(\d+)$/ ? $1 : () } @cpu;
my @sys = map { /^(\d+)\;(\d+)\;(\d+)$/ ? $2 : () } @cpu;
my @wti = map { /^(\d+)\;(\d+)\;(\d+)$/ ? $3 : () } @cpu;
my @swapfree = map { /^(\d+)\;(\d+)$/ ? $1 : () } @mem;
my @physfree = map { /^(\d+)\;(\d+)$/ ? $2 : () } @mem;
 

my @stamps = map { /^(.*)\s+(\d+\:\d+)\:(.*)$/ ? $2 : () } @stamp;

my @data = ( [ @stamps ], [ @loads ], [@loads2] );

my $xtick = 1;
$xtick = 12 unless ($sqlquery);

my $graph = GD::Graph::bars->new(400,200);

$graph->set( y_label => 'Load',
	     x_label => 'Time',
	     title   => 'Average System Load',
	     long_ticks => 1,
	     x_label_skip => $xtick,
	     x_labels_vertical => 1,
	     x_label_position => 1/2,
	     overwrite => 1,
	     legend_placement => "BC",
	     transparent => 1);

$graph->set_legend( 'Current', '5 minute average' );
my $gd = $graph->plot(\@data);

write_file("/usr/local/apache/htdocs/loads_$host.png", $gd->png);

@data = ( [ @stamps ], [ @physfree ] );
my $graph2 = GD::Graph::bars->new(400,200);
$graph2->set( y_label => 'Free Kilobytes',
	     x_label => 'Time',
	     title   => 'Free Memory',
	     x_label_skip => $xtick,
	     long_ticks => 1,
	     x_labels_vertical => 1,
             x_label_position => 1/2,
	     overwrite => 1,
	     legend_placement => "BC");
$graph2->set_legend( 'Free Memory' );
write_file("/usr/local/apache/htdocs/freemem_$host.png", $graph2->plot(\@data)->png);

@data = ( [ @stamps ], [ @swapfree ] );
$graph2 = GD::Graph::bars->new(400,200);
$graph2->set( y_label => 'Free Kilobytes',
	     x_label => 'Time',
	     title   => 'Free Swap',
	     x_label_skip => $xtick,
	     long_ticks => 1,
	     x_labels_vertical => 1,
             x_label_position => 1/2,
	     overwrite => 1,
	     legend_placement => "BC");
$graph2->set_legend( 'Free Swap' );
write_file("/usr/local/apache/htdocs/freeswp_$host.png", $graph2->plot(\@data)->png);

print qq{<tr><td colspan=2 align="center"><center><img src="/loads_$host.png"></center></td><td colspan=2 align="center"><center><img src="/freemem_$host.png"></center></td></tr>};

@data = ( [ @stamps ] , [ @usr ], [ @sys ], [ @wti] );

my $graph3 = GD::Graph::bars->new(400,200);

$graph3->set( y_label => 'CPU % Usage',
	     x_label => 'Time',
	     title   => 'CPU Time Usage Profile',
	     x_label_skip => $xtick,
	     long_ticks => 1,
	     x_labels_vertical => 1,
             x_label_position => 1/2,
	     overwrite => 1,
	     legend_placement => "BC");

$graph3->set_legend( 'User', 'System', 'I/O Wait' );

write_file("/usr/local/apache/htdocs/cpu_$host.png", $graph3->plot(\@data)->png);

print qq{<tr><td colspan=2 width=50%><center><img src="/cpu_$host.png"></center></td><td colspan=2 width=50%><center><img src="/freeswp_$host.png"></center></td></tr>\n};

$sth = $dbh->prepare("select mounts from $host order by stamp desc limit 1");

$sth->execute();

my @mounts = split(/ /, $sth->fetchrow_array);

my ($i, $filename, $pie, $mountr, $used, $avail, $perct);

my $table = 1;
qx{ rm -f /usr/local/apache/htdocs/pie*.png };
foreach (@mounts) {

	$pie = GD::Graph::pie->new(150,150);
	$mountr = $_; $used = $_; $perct = $_; $avail = $_;

	$mountr =~ s/^(.*)\=\>(.*)/$1/;
	$used =~ s/^(.*)\=\>(.*)\;(.*)\;(.*)$/$4/;
	$avail =~ s/^(.*)\=\>(.*)\;(.*)\;(.*)$/$3/;
	$perct =~ s/^(.*)\=\>(.*)\;(.*)\;(.*)$/$2/;
	#print "$_<br>$mountr<br>$used<br>$avail<br>$perct";
	my $perct2 = 100 - $perct;
	@data = ( [ qq{$avail}, qq{$used} ],
		[ ( $perct, $perct2 ) ] );

	$pie->set( label => "[$perct\% used]" );

	$gd = $pie->plot(\@data);
	
	$i++;
	$filename = "pie$i\_$host"; 
	open(IMG, "> /usr/local/apache/htdocs/$filename.png") or die $!;
	binmode IMG;
	print IMG $gd->png;
	close IMG;

	print qq{<td width="25\%"><center><font face="Arial, Helvetica, sans-serif" size="-1"><img src=/$filename.png><br>$mountr</font></center></td>\n};
	$table++;
	if ($table > 4) { print "</tr>\n<tr>"; $table = 1; }
}
print "</tr></td></table>";
print end_html;
$sth->finish();
$dbh->disconnect();
