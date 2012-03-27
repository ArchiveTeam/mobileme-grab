#!/bin/bash
#
# Usage: ./monitor-free-space.sh ${THRESHOLD}
#
# Calculates free space of the data directory's filesystem roughly every 30
# seconds.  If the space consumed by data exceeds a given threshold, touches
# STOP in the script directory.
#
# The threshold must be specified in gibibytes.
#
# It is assumed that this script will be run from the same directory as
# dld-client.sh.  If it isn't, then nothing will work as advertised.
#
# Because this script gracefully stops downloads, the amount of free space left
# on the filesystem containing the data directory will almost always be less
# than the configured threshold.  If you are tight on disk space, then, you
# should give yourself a margin of a couple gibibytes.  Adjust as your
# risk-taking sense dictates.

threshold="$1"
triggered=0

# If df on your system isn't GNU df, you'll need to fix this up.  More-or-less
# equivalent configuration for a BSD userland:
#
# DF='df -g data'
#
# It isn't a perfect correspondence -- BSD df lists 1G-blocks starting from
# zero, not one -- but it's good enough.
DF='gdf -BG data'

if [[ -z $threshold ]]; then
	echo "Usage: $0 {free space threshold in gibibytes}"
	exit 1
fi

while true; do
	available=`$DF | tail -n 1 | awk '{print $4}' | sed -e 's/[^0-9]//g'`

	echo "[`date`] data filesystem: $available GiB free, will touch STOP when $threshold GiB are free" 

	if [[ $available -le $threshold ]]; then
		if [[ triggered -ne 1 ]]; then
			echo "$available GiB <= $threshold GiB; telling client it should stop."
			touch STOP
			triggered=1
		fi
	fi

	sleep 30
done
