#!/bin/ksh

# snoop.sh
# use OpenBSD's accounting to determine who has been running
# which commands.

sa -u | perl -nle 'split /\s+/; printf q+%15s %15s %c+, [getpwuid $_[1]]->[0],$_[8].$/' | sort -u | less
