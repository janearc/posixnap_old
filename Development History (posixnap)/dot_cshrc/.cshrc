# alex avriette's cshrc.
# see comments for stuff you should probably be changing

# I am no longer using tcsh. I will maintain this document
# in some minor detail for purposes of having a working
# csh environment, where necessary. Please see my zshrc, in
# my cvs repository, for my current environment.

# http://minotaur.posixnap.net/cgi-bin/cvsweb.cgi/

# credits
# tiny pieces of this were taken from the openbsd .cshrc. additional
# pieces were taken from fred sanchez' cshrc and athena init's
# which apple used in darwin. bits of it were taken from Paul DuBois'
# _Using Csh and Tcsh_ by ORA.

# note, apple removed all this stuff as of 10.2 ("jaguar"). 
# shame on them.

# $Revision: 1.31 $
# $Date: 2004-02-14 21:07:35 $

# impending tru64 fix
# mini.underdogma.net> uname -a
# OSF1 mini.underdogma.net V5.1 732 alpha
# mini.underdogma.net> uname -s
# OSF1
# and it needs builtin_iris-ansi

# previously, we used $?prompt. Solaris `which` is a csh script
# however, which does this evilness:

#  set _which_saved_path_ = ( $path )
#  set prompt = ""
#  if ( -r ~/.cshrc && -f ~/.cshrc ) source ~/.cshrc
#  set path = ( $_which_saved_path_ )
#  unset prompt _which_saved_path_

# Eeeeevil. So we can't use `which` with this cshrc unless we trap for the
# solaris which. That makes me angry.

# XXX: we need to make a "which" container so we know when a system is
# NOT okay to run which on (irix, tru64)
if ($?prompt ^ $?_which_saved_path_) then
	# An interactive shell -- set some stuff up

	# first we need some inkling of what OS we're on. if you don't have
	# uname -s, you're in trouble.
	set os_type = `uname -s`

	# file completion
	set filec

	# keep a long history
	set history = 1000

	# allow us to log out with ^D
	unset ignoreeof 

	# track our hostname for later use
	set host = `hostname | sed 's:^\(.*\)\.:\1:'`
	set mch = $host

	# make a modest prompt
	set prompt = "[%m:%c3] $user% "
	alias prompt 'set prompt = "[%m:%c3] $user% "'

	# set a reasonable umask.
	umask 22

	# this will most likely irritate emacs users. comment if you dont like it.
	# ... or just use vi.
	# XXX: we need a test here to determine whether we're running in tcsh
	# or csh, since csh will squawk and behave badly. this is exacerbated by
	# the 'which' dilemma.
	bindkey  forward-word
	bindkey  backward-word
	bindkey  backward-delete-word

	# you may not want this on solaris.
	# we do this so we can javac servlet pages.
	setenv CLASSPATH /usr/local/tomcat/lib
	
	# this may be "/usr/dict/words" on linux or
	# "/usr/share/dict/web2" on darwin.
	setenv dict /usr/share/dict/words

	# solaris does not have a whoami, so let's fix their wagons here.
	if ("SunOS" =~ $os_type) then
		alias whoami "who am i | cut -d' ' -f1"
	endif

	# {{{ ALIASES 

	alias df	df -k
	alias du	du -k
	alias f		finger
	alias h		'history -r | more'
	alias j		jobs -l
	alias tset	'set noglob histchars=""; eval `\tset -s \!*`; unset noglob histchars'
	alias .   'pwd'   
	alias ..  'cd ..' 
	alias cd..  'cd ..' 
	alias cl 'cd \!*; ls -l'
	alias cdwd  'cd `pwd`'
	alias cwd 'echo $cwd'
	alias files 'find \!:1 -type f -print'  # files x => list files in x
	alias ff  'find . -name \!:1 -print'  # ff x => find file named x
	alias line  'sed -n '\''\!:1 p'\'' \!:2'  # line 5 file => show line 5 of file
	alias l   'ls -lg'
	alias ll  'ls -lag \!* | less'
	alias lt  'ls -ltr \!* | tail -5'
	alias term  'set noglob; unsetenv TERMCAP; eval `tset -s -I -Q - \!*`'
	alias word  "grep \!* $dict" # Grep thru dictionary
	alias wordcount '(cat \!* | tr -s '\''  .,;:?\!()[]"'\'' '\''\012'\'' |' \
	    'cat -n | tail -1 | awk '\''{print $1}'\'')' # Histogram words
	alias vim 'vim -T builtin_iris-ansi -u ~/.vimrc'
	alias pa  'ps xauw'
	alias pu  'ps xawu | grep -i'
	alias psme  "ps xuaw | grep $user | sort -k 5,5 | grep -v grep"
	alias mod 'perl -M\!* -ce 1'
	alias mkdir 'mkdir -p'
	alias vimscape 'wget -qO - \!* | vim - '
	alias perlvim 'vim `perldoc -l \!*`'
	alias bench "time perl -le 'require q{bigrat.pl}; print rsqrt(2,10)'"
	alias genpass 'perl -le "print crypt qw/\!* \!*/"'
	alias bc 'bc -l'
	
	# fix some typos
	alias bim 'vim'
	alias cim 'vim'
	alias cmod 'chmod'
	alias cown 'chown'

	# stupid ssh tricks
	alias sshcat "ssh \!:1 'dd of=\!:2'"
	alias keyify "tar cf - $home/.ssh | ssh \!:1 'tar xvf - '"

	# tricks for laziness

	# mnemonic: hopeful cd -- cd to a directory you hope lives 
	# under . but you have forgotten just where. matt is credited
	# with part of this.
	alias hcd 'find . -type d -name \!* -exec cd {} \;'

	# this is a halt alias that works on solaris and on linux. bsd already has
	# halt. this works equally well but you may not like it
	if ( ! -e "`which halt`") then
		alias halt 'shutdown -hn now'
	endif

	# this may piss off some shells and some terminals. basically, change the
	# terminal title bar to be user@host:dir . make sure you have an echo 
	# that has -n. (/usr/ucb/echo on solaris)
	# you may also need to unalias cd for tricks like:
	# (cd /usr ; tar cf freeware) | (cd /mnt/anotherdisk; tar xf -)

	alias cd 'cd \!*; echo -n "]2;`whoami`@`hostname`:`pwd`"'

	# solaris stuff
	# http://www.sun.com/bigadmin/shellme/ for more good stuff
	alias fastreboot '/sbin/uadmin 2 2'
	if (-e /usr/ucb/ps) then
		alias ps '/usr/ucb/ps'
	endif

	if (-e /usr/ucb/echo) then
		alias echo '/usr/ucb/echo'
	endif

	# updating the openbsd source tree
	if ("OpenBSD" =~ $os_type) then
		alias obsd_cvs 'setenv CVSROOT anoncvs@anoncvs.openbsd.org:/cvs ; setenv CVS_RSH /usr/bin/ssh'
		alias obsd_cvs_grab 'cd /usr; cvs -q get -P src'
		alias obsd_cvs_build 'rm -rf /usr/obj/* ; cd /usr/src ; make obj'
		alias obsd_cvs_kernel "cd /usr/src/sys/arch/`machine`/conf ; cp GENERIC `hostname` ; config `hostname` ; cd ../compile/`hostname` ; make clean && make depend && make ; echo 'now we cp /bsd /bsd.old and cp bsd /bsd, you you are going to do that manually.'"
	endif
	
	# updating the apple source tree
	if ("Darwin" =~ $os_type) then
		alias	apple_cvs 'setenv CVSROOT avriettea@anoncvs.cvs.apple.com:/cvs ; setenv CVS_RSH /usr/bin/ssh'
		set apple_trees = "Applications Commands Darwin Documentation Filesystems IO Interfaces Libraries Networking PCSC Ports Scripting Security Services System Tools"
	endif

	# }}} ALIASES

	# {{{ ENV VARS

	# you most likely want to change this.
	setenv DBI_DSN "dbi:Pg:dbname=botdb_elvis;host=goro-i.putar"

	# this should obviously be changed
	# for epic
	setenv IRCNICK tenderpuss
	setenv IRCNAME 'inadvertent ineptitude'
	
	# yay squid
	setenv PROXY 'http://10.1.1.1:3128/'
	
	# source control stuff
	setenv CVSROOT alex@envy.posixnap.net:/cvs
	setenv CVS_RSH `which ssh`
	
	# neopets stuff. http://envy.posixnap.net/cgi-bin/cvsweb/neo/
	setenv NP_HOME $HOME/.neopets

	# }}} ENV VARS
	
endif

set path = ( {,/usr,~}{/{,s}bin} )

if (-e /usr/local) then
	# chances are, we have stuff here.
	set path = ( $path /usr/local/{,s}bin )
endif

if (-e /opt) then
	# we might have stuff here too.
	set path = ( $path /opt/{,s}bin )
endif

if (-e /usr/X11R6) then
	set path = ( $path /usr/X11R6/bin )
endif

if (-e /usr/local/pgsql/bin) then
	set path = ( $path /usr/local/pgsql/bin )
endif

# {{{ VENDOR SPECIFIC PATH ADDITIONS

# YAY OS VENDORS! Thanks for putting everything in such 
# EASY TO REACH PLACES!
if ($?os_type) then

	if ("OpenBSD" =~ $os_type) then
		set path = ( $path /usr/local/jdk1.2-blackdown/bin )
		alias pflogview 'tcpdump -n -e -ttt -r /var/log/pflog'
	endif
	
	if ("SunOS" =~ $os_type) then
		set path = ( $path /usr/{sfw,sadm,xpg4,ucb,ccs,openwin}/bin )
		setenv LD_LIBRARY_PATH /usr/local/lib
		# Jumpstart stuff. I keep a /mnt/jumpstart/bin directory that looks like this:
		# add_install_client -> ../Solaris_9/Tools/add_install_client
		# check -> ../Solaris_9/Misc/jumpstart_sample/check
		# rm_install_client -> ../Solaris_9/Tools/rm_install_client
		if ( -e /mnt/jumpstart/bin ) then
			set path = ( $path /mnt/jumpstart/bin )
		endif
		# the user has installed freeware from the solaris 9 freeware companion
		# cd. let them use it.
		if ( -e /opt/sfw/bin ) then
			set path = ( $path /opt/sfw/{,s}bin )
			setenv LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/opt/sfw/bin"
		endif
		# gnome-terminal really dislikes the iris-ansi setting for vim.
		# the bad news is there's no real good way to determine whether your
		# vim has it. this was pretty much the best i could come up with.
		# you may need to change this.
		if ( -e /opt/sfw/bin/vim ) then
			# at this point youre using sun's vim.
			if ( -e /bin/gnome-terminal ) then
				# and you have installed gnome.
				unalias vim
				alias vim "vim -T builtin_beos-ansi -u ~/.vimrc "
			endif
		endif
		# solaris' version of xev lives here.
		if ( -e /usr/openwin/demo ) then
			set path = ( $path /usr/openwin/demo )
		endif
		# ugh. solaris likes us to use dtpad as our $EDITOR. that just makes
		# me itch.
		setenv EDITOR vim
	endif
	
	if ("Darwin" =~ $os_type) then
		set path = ( $path /Applications )
		alias eeprom nvram
	endif
	
	if ("IRIX64" =~ $os_type) then
		set path = ( $path /usr/{freeware/{,s}bin,bsd,sysadm/{,priv}bin,etc,bin/X11} /etc )
		if (-e /opt/MIPSpro) then
			setenv CC /usr/bin/cc
			setenv CFLAGS "-64"
			# it is safer to use cc for ld than ld. additionally some
			# gnu drivel does not understand LDFLAGS. we just munge LD 
			# for them here. dorks.
			#
			# NOTE: you need to *UN SET* this stuff to use gcc. Postgres
			# and other platforms have problems with gcc being ld.
			setenv LD "/usr/bin/cc $CFLAGS"
	  endif
		unalias ps
		unalias pa
		unalias pu
		unalias psme
		alias pa ps -ef
		alias pu "ps -ef | grep "
		alias psme "ps -ef | grep $user "
	endif
	
	# irix 32 identifies itself differently than irix64.
	if ("IRIX" =~ $os_type) then
		set path = ( $path /usr/{freeware/{,s}bin,bsd,sysadm/{,priv}bin,etc,bin/X11} /etc )
		unalias ps
		unalias pa
		unalias pu
		unalias psme
		alias pa ps -ef
		alias pu 'ps -ef | grep '
		alias psme "ps -ef | grep $user "
	endif

endif

# }}} VENDOR SPECIFIC PATH ADDITIONS
