#!/bin/ksh
##
## cvs_grab.sh
## used to grab an openbsd source tree.
##
CVSROOT=anoncvs@anoncvs.openbsd.org:/cvs; 
CVS_RSH=/usr/bin/ssh; 
export CVSROOT CVS_RSH; 
cd /usr; 
cvs -q get -P src > /mnt/build_logs/`date '+%a_%b_%d'`.src.cvs_get_log 2>&1 
