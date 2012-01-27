#!/bin/bash
#
# Upload complete files to batcave.
#
# This script will look in your data/ directory to find
# users that are finished. It will upload the data for
# these users to the repository using rsync.
#
# You can run this while you're still downloading,
# since it will only upload data that is done.
# After the upload of an account finishes, the files are
# moved to the data/uploaded/ directory.
#
# Usage:
#   ./upload-finished.sh $DEST
# ask SketchCow for your destination name
# note: this is *not* a full rsync url, just the module name
#
# You can set a bwlimit for rsync, e.g.:
#   ./upload-finished.sh $DEST 300
#

destname=$1
dest=batcave.textfiles.com::$1/mobileme/
if [ -z "$dest" ]
then
  echo "Usage:  $0 [dest] [bwlimit]"
  exit
fi
if [[ ! $dest =~ ^[.a-zA-Z0-9]+::[a-zA-Z0-9]+/mobileme/$ ]]
then
  echo "$dest does not look like a proper rsync destination."
  echo "Usage:  $0 [dest] [bwlimit]"
  exit
fi

bwlimit=$2
if [ -n "$bwlimit" ]
then
  bwlimit="--bwlimit=${bwlimit}"
fi

cd data/
for d in ?/*/*/*
do
  if [ -d "${d}/web.me.com" ] && \
     [ -d "${d}/homepage.mac.com" ] && \
     [ -d "${d}/public.me.com" ] && \
     [ -d "${d}/gallery.me.com" ] && \
     [ ! -f "${d}/"*"/.incomplete" ]
  then
    user_dir="${d}/"
    user=$( basename $user_dir )
    echo "Uploading $user"

    echo "${user_dir}" | \
    rsync -avz --partial \
          --compress-level=9 \
          --progress \
          ${bwlimit} \
          --exclude=".incomplete" \
          --exclude="files" \
          --exclude="unique-urls.txt" \
          --recursive \
          --files-from="-" \
          ./ ${dest}
    if [ $? -eq 0 ]
    then
      echo -n "Upload complete. Notifying tracker... "

      success_str="{\"uploader\":\"${destname}\",\"user\":\"${user}\"}"
      tracker_no=$(( RANDOM % 3 ))
      tracker_host="memac-${tracker_no}.heroku.com"
      resp=$( curl -s -f -d "$success_str" http://${tracker_host}/uploaded )
      
      mkdir -p "uploaded/"$( dirname $user_dir )
      mv $user_dir "uploaded/"$user_dir

      echo "done."
    fi
  fi
done

