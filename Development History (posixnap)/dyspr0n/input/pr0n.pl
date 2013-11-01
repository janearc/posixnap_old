package pr0n;

use DBI;
use Carp;

use POSIX qw{ cuserid };

$agent='Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)';
$count=0;
$insert=0;
$site="unknown";

$dbname="pron";
$dbhost="localhost";
$dbuser=cuserid();
$dbpass="";
$table="link_descr_fetched";


$dbh = DBI->connect( $ENV{DBI_DSN} || "dbi:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpass )
                       or  die $DBI::errstr;

$sth_consider=$dbh->prepare("insert into $table values (?,?,false,?,?)");
$sth_count=$dbh->prepare("select count(*) from $table where link=?");
	
$SIG{INT} = sub { print "$0: emergency closing db connection\n" unless $zero ;$dbh->disconnect;exit; } ;

$pr0n::site = "$0";
$pr0n::site =~ s/\.pl$//;
$pr0n::site =~ s/.*\///g;

sub fetchsite {
	my $PROC;
	open PROC, "wget -U \"$agent\" -qO - -Y off \"$_[0]\" |";
	@data = <PROC>;
	close PROC;
	return @data;
}

sub consider {
	my ($link, $desc, $date ) =@_;
	my $rows=1;
	$count++;
#	print "considering $date: $desc: $link\n"; 
	$sth_count->execute($link) or die $DBI::errstr;
	($rows) = $sth_count->fetchrow_array;
#	print "rows = $rows\n";
	if ($rows) {
#		print "already here\n";
	} else {
#		print "inserting: ($link,$desc,$date,$site)\n";	
		$sth_consider->execute($link,$desc,$date,$site) or die $DBI::errstr;
		$insert++;
	}
}

sub fin {
	printf ("considered:%10d inserted:%10d\t( $site )\n", $count, $insert);
	$sth_count->finish;
	$sth_consider->finish;
	$dbh->disconnect;
}

1;
