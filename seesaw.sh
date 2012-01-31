#!/bin/bash
#
# Distributed downloading script for me.com/mac.com.
#
# This script will download a user's data to this computer.
# It uploads the data to batcave and deletes it. It will then
# continue with the next user and repeat.
#
# Usage:
#   ./seesaw.sh $YOURNICK
#
# You can set a bwlimit for the rsync upload, e.g.:
#   ./seesaw.sh $YOURNICK 300
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

# the script also needs curl with SSL support

if ! builtin type -p curl &>/dev/null
then
  echo "You don't have curl."
  exit 3
fi

if ! curl -V | grep -q SSL
then
  echo "Your version of curl doesn't have SSL support."
  exit 3
fi

youralias="$1"
bwlimit=$2

if [[ ! $youralias =~ ^[-A-Za-z0-9_]+$ ]]
then
  echo "Usage:  $0 {nickname}"
  echo "Run with a nickname with only A-Z, a-z, 0-9, - and _"
  exit 4
fi

if [ -n "$bwlimit" ]
then
  bwlimit="--bwlimit=${bwlimit}"
fi

initial_stop_mtime='0'
if [ -f STOP ]
then
  initial_stop_mtime=$( stat -c '%Y' STOP )
fi

while [ ! -f STOP ] || [[ $( stat -c '%Y' STOP ) -le $initial_stop_mtime ]]
do
  # request a username
  echo -n "Getting next username from tracker..."
  tracker_no=$(( RANDOM % 3 ))
  tracker_host="memac-${tracker_no}.heroku.com"
  username=$( curl -s -f -d "{\"downloader\":\"${youralias}\"}" http://${tracker_host}/request )

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

    userdir="${username:0:1}/${username:0:2}/${username:0:3}/${username}"
    dest=batcave.textfiles.com::mobileme/$youralias/
    echo "Uploading $user"

    echo "${userdir}" | \
    rsync -avz --partial \
          --compress-level=9 \
          --progress \
          ${bwlimit} \
          --exclude=".incomplete" \
          --exclude="files" \
          --exclude="unique-urls.txt" \
          --recursive \
          --files-from="-" \
          data/ ${dest}
    result=$?
    if [ $result -eq 0 ]
    then
      echo -n "Upload complete. Notifying tracker... "

      success_str="{\"uploader\":\"${youralias}\",\"user\":\"${username}\"}"
      tracker_no=$(( RANDOM % 3 ))
      tracker_host="memac-${tracker_no}.heroku.com"
      resp=$( curl -s -f -d "$success_str" http://${tracker_host}/uploaded )
      
      rm -rf data/$userdir

      echo "done."
      echo
      echo
    else
      echo
      echo
      echo "An rsync error. Scary!"
      echo
      exit 1
    fi
  fi
done

