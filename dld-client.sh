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

    if ./dld-user.sh "$username"
    then
      # complete

      # statistics!
      i=0
      bytes_str="{"
      domains="web.me.com public.me.com gallery.me.com homepage.mac.com"
      for domain in $domains
      do
        userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/${domain}"
        if [ -d $userdir ]
        then
          bytes=$( du --apparent-size -bs $userdir | cut -f 1 )
          if [[ $i -ne 0 ]]
          then
            bytes_str="${bytes_str},"
          fi
          bytes_str="${bytes_str}\"${domain}\":${bytes}"
          i=$(( i + 1 ))
        fi
      done
      bytes_str="${bytes_str}}"

      success_str="{\"downloader\":\"${youralias}\",\"user\":\"${username}\",\"bytes\":${bytes_str}}"
      echo "Telling tracker that '${username}' is done."
      resp=$( curl -s -f -d "$success_str" http://memac.heroku.com/done )
      if [[ "$resp" != "OK" ]]
      then
        echo "ERROR contacting tracker. Could not mark '$username' done."
        exit 5
      fi
      echo

    else
      echo "Error downloading '$username'."
      exit 6
    fi
  fi
done

