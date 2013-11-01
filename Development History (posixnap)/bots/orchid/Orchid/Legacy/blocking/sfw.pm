sub public {
	my ($thischan, $thisuser, $thismsg) = @_;
	my ($command, $vers, $pack) = split ( / / , $thismsg);
	return unless ($command =~ /^:sfw/);
	my %pages = ( '9' => '/pub/solaris/freeware/sparc/9',
		      '8' => '/pub/solaris/freeware/sparc/8',
		      '7' => '/pub/solaris/freeware/sparc/7',
		      '6' => '/pub/solaris/freeware/sparc/2.6',
		      '2.6' => '/pub/solaris/freeware/sparc/2.6',
		      '2.5.1' => '/pub/solaris/freeware/sparc/2.5',
		      '2.5' => '/pub/solaris/freeware/sparc/2.5' );
	my $ftpserver = 'ftp.ibiblio.org';
	if ($pages{$vers}) {
		# get a package list
		use Net::FTP;
		my $ftp = Net::FTP->new( $ftpserver, Passive => 1);
		$ftp->login("anonymous", 'anonymous@anonymous.com');
		$ftp->cwd($pages{$vers});
		my @packages = grep(/$pack/, $ftp->ls());
		$ftp->quit;
		unless (@packages) { 
			utility::spew($thischan, $thisuser, "$pack not found for Solaris $vers");
			return;
		}
		unless (scalar @packages < 4) { 
			utility::spew($thischan, $thisuser, "List too long. Consider narrowing search or using a private message.");
			return;
		}
		foreach (@packages) {
			utility::spew($thischan, $thisuser, "ftp://$ftpserver$pages{$vers}/$_");
		}
	}
	else {
		utility::spew($thischan, $thisuser, "$vers is not a valid solaris version");
	}
}

sub emote {
	()
}

sub private {
        my ($thischan, $thisuser, $thismsg) = @_;
        my ($command, $vers, $pack) = split ( / / , $thismsg);
        return unless ($command =~ /^:sfw/);
        my %pages = ( '9' => '/pub/solaris/freeware/sparc/9',
                      '8' => '/pub/solaris/freeware/sparc/8',
                      '7' => '/pub/solaris/freeware/sparc/7',
                      '6' => '/pub/solaris/freeware/sparc/2.6',
                      '2.6' => '/pub/solaris/freeware/sparc/2.6',
                      '2.5.1' => '/pub/solaris/freeware/sparc/2.5',
                      '2.5' => '/pub/solaris/freeware/sparc/2.5' );
        my $ftpserver = 'ftp.ibiblio.org';
        if ($pages{$vers}) {
                # get a package list
                use Net::FTP;
                my $ftp = Net::FTP->new( $ftpserver, Passive => 1);
                $ftp->login("anonymous", 'anonymous@anonymous.com');
                $ftp->cwd($pages{$vers});
                my @packages = grep(/$pack/, $ftp->ls());
                $ftp->quit;
                unless (@packages) {
                        utility::spew($thischan, $thisuser, "$pack not found for Solaris $vers");
                        return;
                }
                foreach (@packages) {
                        utility::spew($thischan, $thisuser, "ftp://$ftpserver$pages{$vers}/$_");
                }
        }
        else {
                utility::spew($thischan, $thisuser, "$vers is not a valid solaris version");
        }

}

sub help {
	my ($thischan, $thisuser, $thismsg) = (@_);
	utility::spew( $thischan, $thisuser, $_ ) for split /\n/, <<"HELP";
:sfw [9|8|7|6|2.6|2.5.1|2.5] package
Package can be a full name or a partial name.
This package returns wget ready urls for Sun Freeware packages.
HELP
}

1;
