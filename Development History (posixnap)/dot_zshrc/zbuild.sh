#!/bin/sh

# zbuild.sh
# A script to build my zsh environment from my cvs repository.

# Doug Kilpatrick helped debug the Solaris sh idiocy.

# $Revision: 1.8 $
# $Date: 2004-03-06 04:03:29 $

# You don't even want to *KNOW* how broken Solaris sh is. Also,
# Leenucks keeps test in /usr/bin. This doesn't bother Solaris
# since it hasn't got a concept of "/usr/bin" and "/bin". OpenBSD
# has to just be different, and INSISTS on it being in /bin. So
# naturally, linux and openbsd disagree here. So we fix em both.
TEST=/bin/test
[ -f /usr/bin/test ] && TEST=/usr/bin/test

ZSHRC_PREF="johnston_zshrc"

MANIFEST="$ZSHRC_PREF aliases environment"

for file in $MANIFEST ; do
	if $TEST -e $file ; then
		:
	else
		echo << EOECHO
It appears this is an incomplete checkout."
Cowardly refusing to build environment from possible bad checkout."
exit 0
EOECHO
	fi
done
# If we don't have a hostname, we're hosed.
IFHN=`which hostname`

if $TEST -e "$IFHN" ; then
	:
else 
	echo "This unix is pretty broken. Bailing out."
	exit 0
fi

HOSTNAME=`$IFHN | cut -d. -f1`

# Determine where we're running
IFUN=`which uname`

if $TEST -e "$IFUN" ; then
	:
else
	echo "This unix is pretty broken. Bailing out."
	exit 0
fi

OSTYPE=`$IFUN -s`

# Begin building the environment
BUILD_DIR="/tmp/build_${$}"

echo "Build dir [ $BUILD_DIR ] created."
mkdir $BUILD_DIR

if $TEST -e "os_hints/${OSTYPE}.hints"; then
	echo "Found hints for $OSTYPE, adding them to build..."
	cp os_hints/${OSTYPE}.hints $BUILD_DIR/.zhints
fi

# Start moving files
cp $ZSHRC_PREF $BUILD_DIR/.zshrc
cp aliases $BUILD_DIR/.zaliases
cp environment $BUILD_DIR/.zenvironment

# Site-specific files
$TEST -d "zlocal_${HOSTNAME}" && cp zlocal_${HOSTNAME}/${HOSTNAME} $BUILD_DIR/.zlocal

# add functions
for function in zfunctions/*; do
	# ignore that evil cvs directory
	if $TEST -d "${function}" ; then
		:
	else
		cat $function >> $BUILD_DIR/.zfunctions
	fi
done

cat << EOECHO

  Build seems to have succeeded. It is in $BUILD_DIR.
  Something like : 
    
    ( cd $BUILD_DIR ; tar cf - .* ) | ( cd WHERE_YOU_WANT_IT ; tar xvf - )

  should probably be sufficient.

EOECHO
# aja // vim:tw=80:ts=2:noet:syntax=zsh
