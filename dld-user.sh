#!/bin/bash
#
# Script for downloading the me.com/mac.com data for one user.
#
# This will download web.me.com, homepage.mac.com, public.me.com
# and gallery.me.com.
#
# You need wget-warc to run this script. Please compile it and
# copy the wget executable as wget-warc to the same directory
# as these scripts.
#
# Usage:   dld-user.sh ${USERNAME}
#

if [ ! -x ./wget-warc ]
then
  echo "wget-warc not found. Download and compile wget-warc and save the"
  echo "executable as ./wget-warc"
  exit 3
fi

username="$1"

echo "Downloading ${username} - $(date)"

domains="web.me.com public.me.com gallery.me.com homepage.mac.com"
for domain in $domains
do
  WGET_WARC=./wget-warc ./dld-me-com.sh "$domain" "$username"
  result=$?
  if [ $result -ne 0 ] && [ $result -ne 2 ]
  then
    echo "  Error running ${command}."
    exit 1
  fi
done

echo "  Finished ${username} - $(date)"
echo

exit 0

