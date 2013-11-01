#!/usr/bin/perl -w
# FSK 18
#
# this code is intentionally as dirty as its purpose

$numfiles=4;
$size=13500;
$maxprocs=25;

$warn="\033[33m"; $normal="\033\[m"; $amp="\033\[36m"; 
#############################

$current=0;
$query=0;
$sequence=0;

use File::Basename;
#use Socket;
use DBI;
#use HTTP::Request;
#use LWP::UserAgent;
#use Net::protoent;
use File::Find;
use File::Path;
use Cwd;
use POSIX qw{ cuserid };


$cwd=cwd();
$dbname="pron";
$dbhost="localhost";
$dbuser=cuserid();
$dbpass="";
$table="link_descr_fetched";

$SIG{INT} = sub { print STDERR "\n*** X_X ***\n" ; careforchilds() ;exit; };
$SIG{HUP} = sub { print STDERR "\n*** HUP ***\n"; $limit=1; };

print STDERR "usage: $0 <regexp> ...\n" unless defined $ARGV[0];

$limit=0;
$count=0;
$quiet=0;
$qlink=0;

agent();

foreach (@ARGV) {
	/^u$/ and $qlink=1 and next;
	/^q$/ and $quiet=1 and next;
	/^t$/ and $query=1 and next;
	if ( /^s=[0-9]+$/ ) {
		($size) = /^s=([0-9]+)$/;
		next;
	}
	if ( /^p=[0-9]+$/ ) {
		($maxprocs) = /^p=([0-9]+)$/;
		next;
	}
	if ( /^l=[0-9]+$/ ) {
		($limit) = /^l=([0-9]+)$/;
		next;
	}
	if ( /^[0-9]+$/ ) {
		($limit) = /^([0-9]+)$/;
		next;
	}
	print STDERR "## connecting to database...\n" unless $quiet;
	dbconnect();
	print STDERR "## querying for '$_'...\n" unless $quiet;
	$sth_select_desc->execute($_);	
	print STDERR "## receiving data...\n" unless $quiet;
	$links=0;
	while ( @row = $sth_select_desc->fetchrow_array()) {
		($link_[$links],$descr_[$links],$foo_[$links],$date_[$links],$site_[$links]) = @row;
		$links++;
	}
	dbdisconnect();
	print STDERR "## got $links links\n" unless $quiet;
	$count=0;
	while ( $count<$links ) {
		($link,$descr,$foo,$date,$site) =  ($link_[$count],$descr_[$count],$foo_[$count],$date_[$count],$site_[$count]) ;
		$count++;

		if ( ($limit != 0) && ($count>$limit) ) {
			careforchilds();
			exit;
		}
		dbconnect() unless $query;	
		$sth_fetched->execute($link) unless $query;
		dbdisconnect() unless $query;

		FORK: {
			if ($pid = fork) {
				print STDERR "$warn" ,"[$pid] o_o $date ($site) $descr$normal\n" unless $quiet;
				if (++$current>=$maxprocs) {
	#				print STDERR "waiting for children to finish...\n";
					while ($current>=$maxprocs) {
						$pid=wait;
						die "I lost my children!\n" unless ($pid > -1);
						print STDERR "-$pid- x_x\n" unless $quiet;
						$current--;
					}
				}
	
			} elsif (defined $pid) { 
				dbconnect() unless $query;	
				if (consider($link,$descr,$date,$site)) {
					$dbh->do("update $table set bad = 'true' where link = '$link'") unless $query;
				} else {
					$dbh->do("update $table set bad = 'false' where link = '$link'") unless $query;
				}
				dbdisconnect() unless $query;
				exit;
			} elsif ($! =~ /No more process/) {     
				sleep 5;
				redo FORK;
			} else {	
				die "Can't fork: $!\n";
			}
		}
		$site=0;
	}
}

careforchilds();

sub careforchilds {
	print STDERR "...waiting for last $current children to exit...\n"unless ($quiet);
	while ($current) {
		$pid=wait;
		die "I lost my children!\n" unless ($pid > -1);
		print STDERR "-$pid- x_x\n" unless $quiet;
		$current--;
	}
}

sub consider {
	($link,$descr,$date,$site)=@_;
	return unless ! $query	;
#	print STDERR "$amp","now considering $descr$normal\n";
	do {
		$randx=((int(rand 65535)+$$+time())%65535);
		$dir=sprintf('%s_%04x',$descr,$randx);
	} while (-e "$dir");
	$dir =~ s/[^a-zA-Z0-9]/_/g; 
	$agent=agent();
	print STDERR "*$$* <a href=$amp$link$normal\n" unless $quiet;
	$cmd="wget -a /dev/null --random-wait -T 300 -w 3 -R 'zip,gif,png,mpeg,mpg,pls,avi,wma,wmv,asf,rm,txt,ra,exe,asp,js,css,java,class' -nH -nv -r -l 3 -p -np --proxy off -U \"$agent\" --directory-prefix=\"$dir\" \"$link\"";
#	print STDERR "running $cmd\n";
	system ($cmd);
	$mydir="$cwd/$dir";
	if ( -d $mydir ) {
		mkdir "$dir\_";
		find(\&checkfile, "$mydir");
		sleep 4;
		rmtree ("$mydir");
		$foo="$mydir\_/";
		@somefiles=<$foo*>;
		if ($#somefiles >= $numfiles) {
			printf STDERR ("*$$* :D moved %d files to $dir\n",1+$#somefiles) unless $quiet;
			open NOTE, ">$foo/FROM";
			printf NOTE ("automatically loaded %d files from $link to $dir at ".localtime() . "\n",1+$#somefiles);
			close NOTE;
		} else {
			printf STDERR ("*$$* D: only got %d usable files, throwing dir away, limit is $numfiles\n" , 1+$#somefiles) unless $quiet;
			rmtree ("$mydir\_");
			return 1;
		}
	} else {
		print STDERR "*$$* o_O wget failed\n" unless $quiet;
		return 1;
	}
	return 0;
}

sub checkfile {
	if (/\.jpg$|\.jpeg$/i) {
		if ( (stat $_)[7]>$size) {
			goto trash if /banner/i;
			goto trash if /thumb/i;
			goto trash if /_small\./i;
#			goto trash if /[0-9]+-th?n?\.jp/i;
#			goto trash if /[0-9]+_th?n?\.jp/i;
#			goto trash if /^th_/i;
#			goto trash if /^tn_/i;
#			goto trash if /^tn[0-9]+\.jp/i;
			($destfile) = /.*(\.[^\.]+)/;
			$destfile = sprintf ( '%x%04x%04x%s',time(),$randx,$sequence++,$destfile);
#			print STDERR "$amp","*$$* 8) $_$normal\n";
			system ("mv \"$File::Find::name\"  \"$cwd/$dir\_/$destfile\"");
			return;
		}
	}
trash:	
#	print STDERR "$amp","*$$* =/ $_$normal\n";
}

sub dbconnect {
	$dbh = DBI->connect( $ENV{DBI_DSN} || "dbi:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpass )
                       or  die "!$$! " . $DBI::errstr;
	$sth_select_desc=$dbh->prepare("select * from $table where descr ~* ? and fetched=false order by date desc") unless $qlink;	
	$sth_select_desc=$dbh->prepare("select * from $table where link ~* ? and fetched=false order by date desc") if $qlink;	
	$sth_fetched=$dbh->prepare("update $table set fetched=TRUE where link=?") ;
}

sub dbdisconnect {
	$sth_select_desc->finish unless ! defined $sth_select_desc;
	$sth_fetched->finish unless ! defined $sth_fetched;
	$dbh->disconnect;	
}

sub agent {
	return (
		'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 4.0)',
		'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)',
		'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)',
		'Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)',
		'Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90)',
		'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)',
		'Mozilla/4.0 (compatible; MSIE 4.01; Windows 98)',
		'Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt)',
		'Mozilla/4.0 (compatible; MSIE 5.01; Windows 98)')
		[int(rand 9)];
}

dbdisconnect();
print STDERR "fin\n";
