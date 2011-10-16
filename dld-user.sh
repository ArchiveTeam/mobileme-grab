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

echo
echo $(date)" - Downloading ${username}"
echo
echo $(date)" - web.me.com/${username}:"
WGET_WARC=./wget-warc ./dld-web-me-com.sh "$username"
echo
echo $(date)" - homepage.mac.com/${username}:"
WGET_WARC=./wget-warc ./dld-homepage-mac-com.sh "$username"
echo
echo $(date)" - gallery.me.com/${username}:"
./dld-gallery-me-com.py "$username"
echo
echo $(date)" - public.me.com/${username}:"
./dld-public-me-com.sh "$username"
echo
echo $(date)" - Finished ${username}"
echo
echo

