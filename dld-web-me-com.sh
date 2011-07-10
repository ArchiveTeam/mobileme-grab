#!/bin/bash
#
# Script for downloading the contents of web.me.com for one user.
#
# Usage:   dld-web-me-com.sh ${USERNAME}
#
#
# Version 1.
#

PHANTOMJS=$(which phantomjs)
WGET_WARC=$(which wget)

if [[ ! -x $PHANTOMJS ]]
then
  echo "phantomjs not found. Set the PHANTOMJS variable in the script."
  exit 3
fi
if [[ ! -x $WGET_WARC ]]
then
  echo "wget not found. Set the WGET_WARC variable in the script."
  exit 3
fi
if ! $WGET_WARC --help | grep -q WARC
then
  echo "${WGET_WARC} does not support WARC. Set the WGET_WARC variable in the script."
  exit 3
fi

username="$1"

userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/web"

if [[ -f "${userdir}/.incomplete" ]]
then
  echo "Deleting incomplete result for ${username}"
  rm -rf "${userdir}"
fi

if [[ -d "${userdir}" ]]
then
  echo "Already downloaded ${username}"
  exit 2
fi

mkdir -p "${userdir}"
touch "${userdir}/.incomplete"

echo "Downloading ${username}"

echo " - Discovering urls (takes a while)"
$PHANTOMJS discover.coffee "http://web.me.com/${username}" > urls-$$.txt
count=`cat urls-$$.txt | wc -l`

echo " - Downloading (${count} files)"
$WGET_WARC -q -i urls-$$.txt -O /dev/null --warc-file="$userdir/$username" --warc-max-size=inf

rm urls-$$.txt

rm "${userdir}/.incomplete"

