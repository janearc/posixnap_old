#!/usr/local/bin/bash
##
## create_tunnel.sh
## used to create a port-forwarding ssh tunnel between two hosts.
## e.g., one host behind a firewall to one on the internet. this
## is useful as an alternative to "vpn" software.
##
## currently, a little broken (i.e., the logic at the end). also,
## this script provides no "good" way to ensure that the connection
## stays alive. using "KeepAlive" in the sshd_config file is a
## good start. some firewalls still manage to kill these connections
## however.
##
## XXX: Erica Amemiya suggested using djb's "svc" suite. Look into 
## that.
##
TUNNEL_HOST=$1
TUNNEL_PORT=$2
DEBUG=0
EXTRA_DEBUG=0

PID=`ps xawu | grep ssh | grep $TUNNEL_PORT | grep -v grep`
[ "$EXTRA_DEBUG" -gt 0 ] && echo "PID grep found '$PID'"

if [ "$PID" ]; then
	PIDS=`echo $PID | grep -vE '[^0-9]'`
	if [ "$PIDS" ]; then 
		# uh oh, multiple pids, bad news
		echo -n "multiple pids, killing [ $PIDS ]..."
		kill -9 $PIDS
		echo " killed!"
		echo -n "starting ssh tunnel on ${TUNNEL_HOST}:${TUNNEL_PORT}..."
		ssh-agent tcsh -c "nohup ssh -fNR${TUNNEL_PORT}:localhost:22 $TUNNEL_HOST "
		PID=`ps xawu | grep ssh | grep $TUNNEL_PORT | grep -v grep`
		if [ "$PID" ]; then
			echo " started!"
			exit 0
		else
			echo " ssh did not come up cleanly. [ $? / $! ]"
			exit 255
		fi
	fi # pids check
	# this means there's just one pid. since theres just one pid
	# there's no need to kill it, just let it be, and abort.
	exit 0
else
	# we dont have two pids, and we dont have one pid, therefore
	# the tunnel has died. time to restart.
	[ $EXTRA_DEBUG ] && echo -n "no tunnel was present, "
	echo -n "starting ssh tunnel on ${TUNNEL_HOST}:${TUNNEL_PORT}..."
	ssh-agent tcsh -c "nohup ssh -fNR${TUNNEL_PORT}:localhost:22  $TUNNEL_HOST "
	PID=`ps xawu | grep ssh | grep $TUNNEL_PORT | grep -v grep`
	if [ "$PID" ]; then
		echo " started!"
		exit 0
	else
		echo " ssh did not come up cleanly. [ $? / $! ]"
		exit 255
	fi
fi
touch /tmp/last_check
