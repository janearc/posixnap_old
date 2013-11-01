#!/usr/local/bin/perl

use warnings;
use strict;
use DBI;
use CGI qq/:standard/;
use CGI::Carp qq/fatalsToBrowser/;
use Benchmark;

$|++;

my ($queried, $fontcolor, $bgcolor);

my $dbh = DBI->connect("dbi:Pg:dbname=syslogs;host=172.17.54.254", "tyler")
	or die "Could not connect to database: $!\n";

my $sth = $dbh->prepare("select hostname from hosts");

print header, start_html(-title=>'Syslogdb Interface v0.0.1',
			 -author=>'thardison@modbee.com',
		         -base=>'true',
			 -meta=>{'keywords'=>'syslog postgres database sql seakwall',
				 'copyright'=>'Artistic License'},
			 -BGCOLOR=>'white',
			 -LINK=>'white',
			 -ALINK=>'white',
			 -VLINK=>'white',
			 -FONT=>'Arial, Helvetica, sans-serif');

print qq{<TABLE width="100%" align="center" valign="center" bgcolor=white>
	<tr><td width=15% align="center"> 
	<a href="http://www.postgres.org/"><img src="/postgres.gif"></a>
	<a href="http://www.cpan.org/">
 	<img width=72 height=75 src="/camel.gif"></a><br>
	<a href="http://www.apache.org/"><img width=155 height=50 src="apache-logo.gif"></a>
	</td><td width=70% colspan=3><center><font face="Arial, Helvetica, sans-serif">
 	<h2>Syslogd to SQL<br>Query Interface</h2></font></center></td>
	<td width=15% bgcolor="#594fbf" align=center>
	<font size=+2 color=white face="Arial, Helvetica, sans-serif">
	Powered By<br><img src=/logo_sun_home.gif></font></td></tr><tr>
	<td colspan=5>&nbsp;</td></tr>\n};

my ($sqlquery, @words);

if (param()) {
	my $t0 = new Benchmark;
	my $query;
	my $where;
	#start constructing a query.
	$sqlquery = "select stamp, hostname, ip, log from current_logs "; 
	unless (param('host') =~ /any/i) {
		$query = param('host');
		$sqlquery = $sqlquery . qq{where hostname ~* '$query'};
		$where++;
	}
	unless (param('fmonth') =~ /any/i || param('fday') =~ /any/i || param('fmonth') =~ /any/i) {
		unless ($where) { 
			$sqlquery = $sqlquery . qq{ where stamp >= '} . param('fyear') . '-' . param('fmonth') . '-' . param('fday'). ' ' . param('fhour'). ':' . param('fmin') . qq{' };
			$where++;
		}
		else {
			$sqlquery = $sqlquery . qq{ and stamp >= '} . param('fyear') . '-' . param('fmonth') . '-' . param('fday') . ' ' . param('fhour') . ':' . param('fmin') . qq{' };
		}	
	}
	unless (param('tmonth') =~ /any/i || param('tday') =~ /any/i || param('tmonth') =~ /any/i) {
		unless ($where) {
			$sqlquery = $sqlquery . qq{ where stamp <= '} . param('tyear') . '-' . param('tmonth') . '-' . param('tday') . ' ' . param('thour') . ':' . param('tmin') . qq{' };
			$where++;
		}
		else {
			$sqlquery = $sqlquery . qq{ and stamp <= '} . param('tyear') . '-' . param('tmonth') . '-' . param('tday') . ' ' . param('thour') . ':' . param('tmin') . qq{' };
		}
	}
	if (param('keyword')) {
		@words = split(/ /, param('keyword'));
		unless ($where) { 
			shift @words;
			$sqlquery = $sqlquery . qq{ where log ~* '$_' }; 
			$where++;
		}
		foreach (@words) {		
			$sqlquery = $sqlquery . qq{ and log ~* '$_' }; 
		}
	}
	$sqlquery = $sqlquery . " limit " . param('limit');
	print qq{<tr><td colspan=5><center>$sqlquery</center></td></tr>};
	my $sth3 = $dbh->prepare("$sqlquery");
	$sth3->execute();
	my $color = "whiteonblue";
	my $records;
	while (my @row = $sth3->fetchrow_array ) {
		$records++;
		if ($color =~ /whiteonblue/) { 
			$fontcolor = "white";
			$bgcolor = "blue";
			$color = "blackonlblue";
		}
		else {
			$fontcolor = "black";
			$bgcolor = "lightblue";
			$color = "whiteonblue";
		}
		print qq{<tr><td bgcolor="$bgcolor"><font color="$fontcolor">
			$row[0]</font></td><td colspan=3 bgcolor="$bgcolor">
			<font color="$fontcolor">$row[3]</font></td>
			<td bgcolor="$bgcolor"><font color="$fontcolor">
			<b>$row[1]<br>$row[2]</b></font></td></tr>\n};
	}
	my $t1 = new Benchmark;
	my $td = timediff($t1, $t0);
	print qq{<tr><td colspan=5><center>Total number of records returned: $records Time to process: } . timestr($td) . qq{</center></td></tr></table>}, end_html;
	exit 0;

}

$sth->execute;

my @hosts;
while (my $host = $sth->fetchrow_array) {
	push @hosts, $host;
}


push @hosts, "Any";

print start_form, qq{<tr><td rowspan=2>Host: }, popup_menu(-name=>'host', -values=>\@hosts), 
		    qq{</td><td width=11%>Start query at:</td><td colspan=2><div align=left>Month: },
		    popup_menu(-name=>'fmonth', -values=>['any','1','2','3','4','5','6','7','8',
							  '9','10','11','12']),
		    qq{ Day: }, 
		    popup_menu(-name=>'fday', -values=>['any','1','2','3','4','5','6','7','8','9','10',
							'11','12','13','14','15','16','17','18',
							'19','20','21','22','23','24','25','26',
							'27','28','29','30','31']),
		    qq{ Year: },
		    popup_menu(-name=>'fyear', -values=>['any','2002','2003','2004','2005']),
		    qq{ Hour: },
		    popup_menu(-name=>'fhour', -values=>['0','1','2','3','4','5','6','7','8','9',
							 '10','12','13','14','15','16','17','18',
							 '19','20','21','22','23']),
		    qq{ Minute: },
		    popup_menu(-name=>'fmin', -values=>['0','1','2','3','4','5','6','7','8','9',
							'10','11','12','13','14','15','16','17',
							'18','19','20','21','22','23','24','25',
							'26','27','28','29','30','31','32','33',
							'34','35','36','37','38','39','40','41',
							'42','43','44','45','46','47','48','49',
							'50','51','52','53','54','55','56','57',
							'58','59']),
		    qq{</div></td><td>Keywords: }, 
		    textfield(-name=>'keyword'),
		    qq{</td></tr><tr><td width=11%>End query at</td><td colspan=2><div align=left>Month: },
		    popup_menu(-name=>'tmonth', -values=>['any','1','2','3','4','5','6','7','8',
                                                          '9','10','11','12']),
		    qq{ Day: },
		    popup_menu(-name=>'tday', -values=>['any','1','2','3','4','5','6','7','8','9','
10',
                                                        '11','12','13','14','15','16','17','18',
                                                        '19','20','21','22','23','24','25','26',
                                                        '27','28','29','30','31']),
		    qq{ Year: }, 
		    popup_menu(-name=>'tyear', -values=>['any','2002','2003','2004','2005']),
		    qq{ Hour: },
		    popup_menu(-name=>'thour', -values=>['0','1','2','3','4','5','6','7','8','9',
							 '10','12','13','14','15','16','17','18',
							 '19','20','21','22','23']),
		    qq{ Minute: },
		    popup_menu(-name=>'tmin', -values=>['0','1','2','3','4','5','6','7','8','9',
							'10','11','12','13','14','15','16','17',
							'18','19','20','21','22','23','24','25',
							'26','27','28','29','30','31','32','33',
							'34','35','36','37','38','39','40','41',
							'42','43','44','45','46','47','48','49',
							'50','51','52','53','54','55','56','57',
							'58','59']),
		    qq{</div></td><td>Limit Query: }, popup_menu(-name=>'limit',
							   -values=>['5','10','25','50','100',
								     '250','500']),qq{<br>},
		    submit('Query Database'), qq{</td></tr></table>},
		    end_form, end_html;
