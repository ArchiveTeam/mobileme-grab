#!/bin/bash
#
# Fix script errors in early downloads.
#
# This script will look in your data/ directory for downloads and
# fix the following (if necessary):
#
#  * Fix for the first-generation web.me.com downloader,
#    which didn't always download every iWeb site.
#
# Note: this script will NOT fix any user that's still being
# downloaded, that is, anything that has an .incomplete file.
# This means that you can run this script while a normal
# client is downloading, but you can't use this script to fix
# interrupted downloads.
#
# Usage:   fix-dld.sh ${YOURALIAS}
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

initial_stop_mtime='0'
if [ -f STOP ]
then
  initial_stop_mtime=$( ./filemtime-helper.sh STOP )
fi

for d in data/*/*/*/*
do
  username=$( basename "$d" )
  need_fix=0

  if [ -f "${d}/"*"/.incomplete" ]
  then
    echo "${username} is still incomplete, not fixing."
    continue
  fi

  # FIX 1: check for early web.me.com downloads
  if [[ ! -f "${d}/web.me.com/wget-discovery.log" ]]
  then
    echo "The web.me.com download of ${username} needs to be fixed."
    touch "${d}/web.me.com/.incomplete"
    need_fix=1
  fi

  # fix, if necessary
  if [[ $need_fix -eq 1 ]]
  then
    if ! ./dld-single.sh "$youralias" "$username"
    then
      exit 6
    fi
  fi

  if [ -f STOP ] && [[ $( ./filemtime-helper.sh STOP ) -gt $initial_stop_mtime ]]
  then
    exit
  fi
done

