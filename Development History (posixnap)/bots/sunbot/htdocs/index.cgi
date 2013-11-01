#!/usr/local/bin/perl

use warnings;
use strict;
use DBI;
use CGI qw{:standard};
use CGI::Carp qw{fatalsToBrowser};

my $host;

my $dbh = DBI->connect("dbi:Pg:dbname=sys_monitor;host=172.17.54.254", "tyler")
	or die ("Couldnt connect to database! $!");

my @tables = grep { !/^pg/ } $dbh->tables;

print header, start_html(-title=>'Power to the People',
			 -author=>'thardison@modbee.com',
			 -base=>'true',
			 -meta=>{'keywords'=>'sun metrics tracking',
			        'copyright'=>'Artistic License'},
			 -BGCOLOR=>'white',
			 -LINK=>'white',
			 -ALINK=>'white',
			 -VLINK=>'white'), qq{<TABLE width="100%" align="center" valign="center" bg
color=white ><tr><td width=15% align="center"> 
<a href="http://www.postgres.org/"><img src="/postgres.gif"></a><a href="http://www.cpan.org/"><img width=72 height=75 src="/camel.gif"></a><br><a href="http://www.apache.org/"><img width=155 height=50 src="apache-logo.gif"></a></td><td width=70% colspan=3><center><font face="Arial,
 Helvetica, sans-serif"><h2>Server Metric Tracking<br>for Unix Based Systems</h2></font></center></td>
<td width=15% bgcolor="#594fbf" align=center><font size=+2 color=white fave="Arial, Helvetica, sans
-serif">Powered By<br><img src=/logo_sun_home.gif></font></td></tr><tr><td colspan=1>&nbsp;</td><td colspan=3 bgcolor="#594fbf"><center>.:<a href="/syslog.cgi">SYSLOGS</a>::<a href="/infrastructure/">FORUMS</a>:.</center></td><td>&nbsp;</td></tr><tr>\n};

my $rowcount = 1;
my $color = "one";
foreach $host (@tables) {
	if ($rowcount > 5) { print "</tr>\n<tr>"; $rowcount = 1 }
	my $sth = $dbh->prepare("select stamp,uptime from $host order by stamp desc limit 1");
	$sth->execute();
	my @select = $sth->fetchrow_array;
	$sth->finish();
	if ($color =~ /one/) { 
		$color = "two";	
		print qq{<td bgcolor="#594fbf" width=20%><font size=+1 color=white face="Arial, Helvetica, sans-serif"><center><a href="/gdtest.cgi?$host" target="_blank">$host</a></center></font><br><font size=-1 color=white face="Arial, Helvetica, sans-serif"><center>Last Poll: $select[0]<br>Uptime: $select[1]</center></font></td>};
		$rowcount++;
		next;
	}
	if ($color =~ /two/) { 
		$color = "one";	
		print qq{<td bgcolor="#594fbf" width=20%><font size=+1 color=white face="Arial, Helvetica, sans-serif"><center><a href="/gdtest.cgi?$host" target="_blank">$host</a></center></font><br><font size=-1 color=white face="Arial, Helvetica, sans-serif"><center>Last Poll: $select[0]<br>Uptime: $select[1]</center></font></td>};
		$rowcount++;
		next;
	}
}

print "</tr></table>",end_html;
$dbh->disconnect();
