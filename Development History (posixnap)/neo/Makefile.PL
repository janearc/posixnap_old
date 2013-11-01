# ExtUtils::AutoInstall Bootstrap Code, version 4.
BEGIN {
    my $p = 'ExtUtils::AutoInstall';
    my $v = .30;
    eval "use $p $v;1"
      or ( $ENV{PERL_EXTUTILS_AUTOINSTALL} !~ /--(?:default|skip|testonly)/
        and ( -t STDIN )
        or eval
        "use ExtUtils::MakeMaker;WriteMakefile('PR' .'EREQ_PM'=>{'$p',$v});1"
        and exit )
      and print "==> $p $v needed. " . "Install it from CPAN? [Y/n] "
      and <STDIN> !~ /^n/i
      and print "***" . " Fetching $p\n"
      and do {
        eval { require CPANPLUS; CPANPLUS::install $p};
        eval "use $p $v;1" or eval { require CPAN; CPAN::install $p};
        eval "use $p $v;1" or die "Please install $p $v manually first...\n";
      }
}

use strict;
use ExtUtils::MakeMaker;

use 5.005_03;

ExtUtils::AutoInstall->import
  ( -version => '0.32',
    -core => [
        Carp          => '',
        Exporter      => '',
        IO            => '',
        POSIX         => '',
        Socket        => '',
       'Data::Dumper' => '',
    ],
    "Terminal Manipulation" => [
        -default  => 1,
        'Term::ReadKey' => '',
    ],
    "Convenience modules" => [
        -default  => 1,
        'Getopt::Long' => '',
        'File::Slurp' => '',
        'CPANPLUS' => '',
    ],
    "HTTP Manipulation modules" => [
        -default        => 1,
        'LWP::UserAgent' => '',
        'HTTP::Cookies' => '',
        'HTTP::Headers' => '',
        'HTML::TableContentParser' => '',
    ],
    "Interface Management modules" => [
        -default => 1,
        'Term::ANSIColor' => '',
    ],
    "Optional Configuration modules" => [
        -default => 1,
        'XML::Simple' => '',
    ],
);

WriteMakefile(
    NAME        => 'Neopets',
    DISTNAME    => 'Neopets',
    AUTHOR      => 'Alex Avriette and Matt Harrington',
    dist      => { COMPRESS => 'gzip', SUFFIX => '.gz'},
    VERSION_FROM => 'Neopets/Agent.pm', # finds $VERSION
    PMLIBDIRS => ['Neopets' ],
    EXE_FILES => ['examples/np_login.pl'],
    LIBS      => [''],   # e.g., '-lm' 
    DEFINE    => '',     # e.g., '-DHAVE_SOMETHING' 
    INC       => '',     # e.g., '-I/usr/include/other' 
);
