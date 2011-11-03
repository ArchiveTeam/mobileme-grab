#!/bin/bash
#
# Distributed downloading script for me.com/mac.com.
#
# This will get a username from the tracker and download data
# from web.me.com, homepage.mac.com, public.me.com and
# gallery.me.com.
#
# You need wget-warc to run this script. Please compile it and
# copy the wget executable as wget-warc to the same directory
# as these scripts.
#
# Usage:   dld-client.sh ${YOURALIAS}
#
# To stop the script gracefully,  touch STOP  in the script's
# working directory. The script will then finish the current
# user and stop.
#

# this script needs wget-warc, which you can find on the ArchiveTeam wiki.
# copy the wget executable to this script's working directory and rename
# it to wget-warc

if [ ! -x ./wget-warc ]
then
  echo "wget-warc not found. Download and compile wget-warc and save the"
  echo "executable as ./wget-warc"
  exit 3
fi

youralias="$1"

if [[ ! $youralias =~ ^[-A-Za-z0-9_]+$ ]]
then
  echo "Usage:  $0 {nickname}"
  echo "Run with a nickname with only A-Z, a-z, 0-9, - and _"
  exit 4
fi

while [ ! -f STOP ]
do
  # request a username
  echo -n "Getting next username from tracker..."
  username=$( curl -s -f -d "{\"downloader\":\"${youralias}\"}" http://memac.heroku.com/request )

  # empty?
  if [ -z $username ]
  then
    echo
    echo "No username. Sleeping for 30 seconds..."
    echo
    sleep 30
  else
    echo " done."

    if ! ./dld-single.sh "$youralias" "$username"
    then
      echo "Error downloading '$username'."
      exit 6
    fi
  fi
done

