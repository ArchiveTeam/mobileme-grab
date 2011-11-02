#!/bin/bash
#
# Downloads a single user and tells the tracker it's done.
# This can be handy if dld-client.sh failed and you'd like
# to retry the user.
#
# Usage:   dld-single.sh ${YOURALIAS} ${USERNAME}
#

youralias="$1"
username="$2"

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
fi

