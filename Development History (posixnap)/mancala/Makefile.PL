# ExtUtils::AutoInstall Bootstrap Code, version 4.
BEGIN{my $p='ExtUtils::AutoInstall';my$v=.30;eval"use $p $v;1"or ($ENV{PERL_EXTUTILS_AUTOINSTALL}!~/--(?:default|skip|testonly)/ and(-t STDIN)or eval"use ExtUtils::MakeMaker;WriteMakefile('PR' .'EREQ_PM'=>{'$p',$v});1"and exit)and print"==> $p $v needed. " ."Install it from CPAN? [Y/n] "and<STDIN>!~/^n/i and print"***" ." Fetching $p\n"and do{eval{require CPANPLUS;CPANPLUS::install $p};eval"use $p $v;1"or eval{require CPAN;CPAN::install$p};eval "use $p $v;1"or die"Please install $p $v manually first...\n"}}

use strict;

use 5.005_03;

use ExtUtils::AutoInstall
  ( -version => '0.32',
    -core => [
        Carp          => '',
        Exporter      => '',
        IO            => '',
        POSIX         => '',
        Socket        => '',
       'Data::Dumper' => '',
    ],
    "Convenience modules" => [
        -default  => 1,
        'CPANPLUS' => '',
    ],
    "Data Manipulation modules" => [
        -default => 1,
        Clone => '',
        FreezeThaw => '',
    ],
    "Array Manipulation modules" => [
        -default => 1,
        "List::Util" => '',
    ],
);

WriteMakefile(
    NAME        => 'Mancala',
    DISTNAME    => 'Mancala',
    AUTHOR      => 'Matt Harrington',
    dist      => { COMPRESS => 'gzip', SUFFIX => '.gz'},
    VERSION_FROM => 'Mancala/Board.pm', # finds $VERSION
    PMLIBDIRS => ['Mancala' ],
    EXE_FILES => [''],
    LIBS      => [''],   # e.g., '-lm' 
    DEFINE    => '',     # e.g., '-DHAVE_SOMETHING' 
    INC       => '',     # e.g., '-I/usr/include/other' 
);
