#
# Solaris
# Use this script to set up your environment for orchid
# upon logging in, if you like. Note that these variables
# are required by the Orchid make process
#

#!/bin/csh
/usr/xpg4/bin/env PATH="/home/alex/bin:${PATH}" ORCHID_HOME="${HOME}/bots/orchid" PERL="${HOME}/bin/perl" tcsh -f
