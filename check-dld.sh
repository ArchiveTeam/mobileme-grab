#!/bin/bash
#
# Check your downloads.
#
# This script will look in your data/ directory for downloads and
# tell you which users are incomplete and/or need to be fixed.
# It will not actually fix anything.
#
# Usage:   check-dld.sh
#

if [ -z $DATA_DIR ]
then
  DATA_DIR=data
fi

for d in $DATA_DIR/*/*/*/*
do
  username=$( basename "$d" )

  # check for any incomplete downloads
  if [ -f "${d}/"*"/.incomplete" ]
  then
    echo "${username} is still incomplete."
    continue
  fi

  # FIX 1: check for early web.me.com downloads
  if [[ ! -f "${d}/web.me.com/wget-discovery.log" ]]
  then
    echo "${username} needs to be fixed (web.me.com)."
  fi
done

