#!/bin/ksh
##
## kernel_build.sh
## used to build an openbsd kernel. useful for daily builds.
##
cd /sys/arch/`machine`/conf; 
cp GENERIC `hostname -s`_`date '+%b%d'`; 
config `hostname -s`_`date '+%b%d'`; 
cd ../compile/`hostname -s`_`date '+%b%d'`; 
make clean depend; 
make; 
cp bsd /mnt/kernels/`hostname -s`_`date '+%b%d'`
