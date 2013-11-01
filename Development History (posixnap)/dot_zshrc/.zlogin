# alex avriette's .zlogin
# see comments for stuff you should probably be changing

# note that this is probably compatible with bash, although
# i personally never touch the stuff.

# credits
# some of this was taken from the openbsd .cshrc. additional
# pieces were taken from fred sanchez' cshrc and athena init's
# which apple used in darwin.

# note, apple removed all that stuff as of 10.2 ("jaguar"). 
# shame on them.

# last revision, 11/4/02

# set these variables to 0 if you dont like them.

# set -x # really hideously ugly, but good for debugging.

WANT_GNU_TAR=1
WANT_BSD_PS=1
WANT_NFS_HOMEDIR=1
WANT_VIM=1
WANTED_TERMINAL="builtin_ansi" # this is for vim, not $TERM
WANT_SNOTTY_LOGIN=1
VIMRC="$HOME/.vimrc"

TERM=vt100

OS_TYPE=`uname -s`

# i do this because I nfs export my home directory from my fileserver.
# if i see my home directory mounted, i cd there and set it to be my
# home directory. this is conditional because if it isnt mounted, 
# messing up $HOME can make life suck.
if [ -e /mnt/home/$USER -a $WANT_NFS_HOMEDIR ]; then
	HOME=/mnt/home/$USER
	cd # takes us home
	export HOME
fi

#
# set up some "friendlier" commands
#

# bsd ps -- if you gotta pick one, go with bsd.
if [ -x /usr/ucb/ps -a $WANT_BSD_PS ]; then
	alias ps=/usr/ucb/ps
fi

# gnu tar -- generally supports bzip and gzip.
# let's see if we can find it
PATH_WITH_SPACES="`echo $PATH | sed 's/:/ /g'`"
GTAR=`which gtar | sed 's:.*/::'`
GNUTAR=`which gnutar | sed 's:.*/::'` # apple calls it gnutar.
TAR_VERSION="`tar --version 2>&1 | grep GNU | sed 's/.*?\(GNU\).*/\1/'`"
if [ "xgtar" = "x${GTAR}" -a $WANT_GNU_TAR ]; then
	alias tar=gtar
elif [ "xgnutar" = "x${GNUTAR}" -a $WANT_GNU_TAR ]; then
	alias tar=gnutar
	alias gtar=gnutar
elif [ "x" != "x${TAR_VERSION}" -a $WANT_GNU_TAR]; then
	alias gtar=tar
else 
	alias gtar="echo 'no gnu tar exists on this system.'"
fi

# set up an editor
unalias vim # this will mess up the sed below.
VIM="`which vim 2>&1 | grep vim | sed 's:.*/::'`"
if [ "xvim" -eq "x${VIM}" ]; then
	alias vi="vim -T ${WANTED_TERMINAL} -u ${VIMRC}"
	alias vim="vim -T ${WANTED_TERMINAL} -u ${VIMRC}"
	alias bim=vim
fi


# updating source trees

# OpenBSD
if [ "xOpenBSD" -eq "x${OS_TYPE}" ]; then
	alias obsd_cvs='export CVSROOT=anoncvs@anoncvs.openbsd.org:/cvs ; \
		export CVS_RSH=/usr/bin/ssh'
	alias obsd_cvs_grab='cd /usr; cvs -q get -P src'
	alias obsd_cvs_build='rm -rf /usr/obj/* ; cd /usr/src ; make obj'
	alias obsd_cvs_kernel="cd /usr/src/sys/arch/`machine`/conf ; \
		cp GENERIC `hostname` ; config `hostname` ; \
		cd ../compile/`hostname` ; make clean && \
		make depend && \
		make ; \
		echo 'now we cp /bsd /bsd.old and cp bsd /bsd, \
		and you are going to do that manually.'"

# Darwin (MacOS X) -- you need to change your CVSROOT
elif [ "xDarwin" -eq "x${OS_TYPE}" ]; then
	alias	apple_cvs='export CVSROOT=avriettea@anoncvs.cvs.apple.com:/cvs ; \
		export CVS_RSH=/usr/bin/ssh'
	APPLE_TREES="Applications Commands Darwin Documentation Filesystems \
		IO Interfaces Libraries Networking PCSC Ports Scripting Security \ 
		Services System Tools"
fi

# here are some aliases i use frequently

alias df='df -k'
alias du='du -k'
alias f=finger
alias history='history -r'
alias j=jobs
alias .=pwd
alias ..='cd ..'
alias cd..='cd ..'
alias cwd=pwd
alias l='ls -la'
alias ll='ls -la | less'
alias lt='ls -ltr | tail -5'
alias mkdir='mkdir -p'
alias pu='ps xawu | grep -i '
alias pa='ps xawu'
alias psme='ps xawu | grep -i $USER'

# fix some typos

alias bi=vi
alias cown=chown
alias cmod=chmod
alias xargz=xargs

# OS-Specific aliases
if [ "xSunOS" -eq "x${OS_TYPE}" ]; then
	alias fastreboot='/sbin/uadmin 2 2'
fi
if [ "xLinux" -eq "x${OS_TYPE}" ]; then
	alias halt='shutdown -hn now'
fi

# IRC environment, you want to change this.
# irc.posixnap.net, if you must come see me
IRCNICK=dev
IRCNAME=/dev/pf

# scold users for logging in as root.
ID=`id | cut -d= -f2 | sed 's:\(.*\)(.*:\1:'`
if [ `logname` -eq `whoami` -a $WANT_SNOTTY_LOGIN -a $ID -eq 0 ]; then
	echo "Don\'t login as root, use su"
fi

# setting the prompt
# most users find this to be a highly personal reflection of their shelling
# leetness. i like it pretty simple. read zshall(1) for more.
# XXX: this is of course, zsh specific. bash and ksh behave differently, and
# your prompt will get messed up. sorry.
PS1="%U$0%u:%m[%3~] %T %# "

export IRCNICK IRCNAME HOME WANT_SNOTTY_LOGIN WANT_GNU_TAR WANT_BSD_PS \ 
	WANT_NFS_HOMEDIR WANT_VIM WANTED_TERMINAL OS_TYPE VIMRC TERM
