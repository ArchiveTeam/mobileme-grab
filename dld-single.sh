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

if [[ ! $youralias =~ ^[-A-Za-z0-9_]+$ ]]
then
  echo "Usage:  $0 {nickname} {username}"
  echo "Run with a nickname with only A-Z, a-z, 0-9, - and _"
  exit 4
fi

if [ -z $username ]
then
  echo "Usage:  $0 {nickname} {username}"
  echo "Provide a username."
  exit 5
fi

VERSION=$( grep 'VERSION=' dld-me-com.sh | grep -oE "[-0-9.]+" )

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

  # some more statistics
  ids=($( grep -h -oE "<id>urn:apple:iserv:[^<]+" \
            "data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/"*"/webdav-feed.xml" \
            | cut -c 21- | sort | uniq ))
  id="${#ids[*]}:${ids[0]}:${ids[${#ids[*]}-1]}"

  success_str="{\"downloader\":\"${youralias}\",\"user\":\"${username}\",\"bytes\":${bytes_str},\"version\":\"${VERSION}\",\"id\":\"${id}\"}"
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

