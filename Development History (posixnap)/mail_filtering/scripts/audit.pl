#!/usr/bin/perl

# $Revision: 1.7 $
# $Date: 2004-02-27 02:14:53 $

use warnings;
use strict;

use POSIX qw(locale_h);
setlocale (LC_CTYPE, "en_US.ISO8859-1");

use Mail::Audit;
use Mail::Audit::KillDups;
use Mail::Audit::PGP;

use Pod::Usage;

use POE qw{ Session Wheel::SocketFactory Component::LaDBI };

POE::Session->create( 
	inline_states => {
		_start          => \&_start,
	
		_accept         => \&_accept,
		_negotiate      => \&_negotiate,

		wheel_success   => \&wheel_success,
		wheel_failure   => \&wheel_failure,
	
		feed_mail       => \&feed_mail,
		munge           => \&munge,
		save_spam       => \&save_spam,
		dlvr_mail       => \&dlvr_mail,

		poll            => \&poll,

		bail            => \&bail,
	},
	heap => {
		Assassin        => '',
		Assassin_data   =>
			{
			},
		Auditor         => '',
		Auditor_data    => 
			{
				logfile       => '/var/log/spam_monster/sm.log',
				emergency     => "/tmp/$$.EMERGENCY",
				destination   => 'default',
			},
		Wheel           => '',
		Wheel_data      =>
			{
				local_address => '127.0.0.1',
				local_port    => '20090',
				proto         => 'tcp',
				reuse         => 'on',
			},
		Ladbi           => '',
		Ladbi_data      =>
			{
				"connect" => "dbi:Pg:",
				"dbname"  => "dbname=email",
				"dbuser"  => "auditor",
				"dbpass"  => "email_FiLtEr-12398",
			}
		dboperations    => 
			{
				constants  =>
					{
						SENDER => 0,
						RECIP  => 1,
						LIST   => 2,
						BODY   => 4,
					},
				statements =>
					{
						store_message    => 
							{
								statement  => 'select store_message( ?, ?, ?, ? )',
								args       => [qw{ SENDER RECIP LIST BODY }],
							},
						spam_message     =>
							{
								statement  => 'select spam_message( ? )',
								args       => [qw{ BODY }],
							},
					}
			},
	},
);

sub _start {
	my ($kernel, $heap) = (@_[ KERNEL, HEAP ]);

	$heap->{Auditor}  = Mail::Audit->
		new( 
			'log'           => $heap->{Auditor_data}->{logfile},
			'emergency'     => $heap->{Auditor_data}->{emergency},
		) or die 'Auditor could not be instantiated.';

	$heap->{Assassin} = Mail::SpamAssassin->new()
		or die 'Assassin could not be instantiated.';

	$heap->{Ladbi}    = POE::Component::LaDBI->create( alias => 'ladbi' )
		or die 'LaDBI could not be instantiated.';

	$heap->{Wheel}    = POE::Wheel::SocketFactory->
		new(
			BindAddress     => $heap->{Wheel_data}->{'local_address'},
			BindPort        => $heap->{Wheel_data}->{'local_port'   },
			SocketProtocol  => $heap->{Wheel_data}->{'proto'        },
			Reuse           => $heap->{Wheel_data}->{'reuse'        },

			SuccessEvent    => 'wheel_success',
			FailureEvent    => 'wheel_failure',

			SocketDomain    => AF_INET,
			SocketType      => SOCK_STREAM,
			ListenQueue     => SOMAXCONN,
		)
		or die 'SocketFactory could not be instantiated.';
}

$incoming->fix_pgp_headers;

for my $pattern (keys %to_list) {
     $incoming->accept ("$maildir/$to_list{$pattern}/")
         if $incoming->to =~ /$pattern/i
         or $incoming->cc =~ /$pattern/i;
}

for my $pattern (keys %subject_list) {
     $incoming->accept ("$maildir/$subject_list{$pattern}/")
         if $incoming->subject =~ /$pattern/i;
}

for my $pattern (keys %from_list) {
     $incoming->accept ("$maildir/$from_list{$pattern}/")
         if $incoming->from =~ /$pattern/i;
}

$incoming->accept ("$maildir/default/");

exit 0;

# Minor helper classes

package Lists; # {{{

use Carp::Assert;
use warnings;
use strict;

my %subject_list = (
	"dc-sage"       => "sage",
	"IAMISC"        => "iamisc"
);

my %from_list = (
	"get-in"        => "spam",
	"dc-sage"       => "sage",
	"usenix"        => "sage",
	"townhall.com"  => "news",
	"epic.org"      => "news",
	"naim-announce" => "news",
	"aolalerts"     => "news",
	"nasa.gov"      => "news",
);

my %to_list = (
	"dc-sage"       => "sage",
	"usenix"        => "sage",
	"sage.org"      => "sage",
	"m-w.com"       => "news",
	"spaceweather"  => "news",
	"stratfor"      => "news",
	"risks"         => "news",
	"secrecy_news"  => "news",
	"IAOPS"         => "news",
	"IAMISC"        => "iamisc",
	"listserv.sup"  => "iamisc",
);

sub new {
	my $class = shift;

	assert( $#_ == 0 );

	return bless {
		Subject => \%subject_list,
		From    => \%from_list,
		To      => \%to_list,
	}, $class;
}

1;
# }}}

package Database; # {{{

use Config;
use DBI;
use Carp;
use Carp::Assert;

my $config = Config->new();

sub new {
	my $class = shift;

	bless { 
		Config => $config,
	}, $class;

	if (@_) {
		assert( not $#_ % 2 );
		my %args = @_;
		if ($args{AutoInstantiate}) {
			my $dbh = $self -> instantiate();
			$self -> {dbh} = $dbh;
		}
	}
	
	return $self;
}

sub instantiate {
	my $self = shift;
	my $config = $self->{Config};

	my $connect_info = $config->db_connect_info();

	assert( @{ $connect_info } == 3 );

	my $dbh = DBI -> connect( @{ $connect_info } )
		or confess DBI -> errstr();

	return $dbh;
}

1;

# }}}

=pod

=head1 NAME

audit.pl

=head1 ABSTRACT

A script to filter very large volumes of email into a database, or to disk.

=head1 SYNOPSIS

Unfortunately, this script does not work at the present time.

=head1 NOTES

To make this called by your mta, add the following to your .forward:

  |"/usr/bin/perl /usr/users/natej/scripts/audit"

=head1 AUTHOR

Alex J. Avriette, alex@posixnap.net. Based upon script written by 
Nate Johnston, natej@aol.net.

=cut

# aja // vim:tw=80:ts=2:noet
