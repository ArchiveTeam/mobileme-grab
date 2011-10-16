#!/bin/bash
#
# Script for downloading the contents of web.me.com for one user.
#
# Usage:   dld-web-me-com.sh ${USERNAME}
#
# Version 3. Started with a new script for web.me.com.
#

if [[ ! -x $WGET_WARC ]]
then
  WGET_WARC=$(which wget)
fi

if [[ ! -x $WGET_WARC ]]
then
  echo "wget not found. Set the WGET_WARC environment variable."
  exit 3
fi
if ! $WGET_WARC --help | grep -q WARC
then
  echo "${WGET_WARC} does not support WARC. Set the WGET_WARC environment variable."
  exit 3
fi

USER_AGENT="AT"

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

echo -n " - Discovering urls..."
$WGET_WARC -U "$USER_AGENT" -q -O "$userdir/webdav-feed.xml" "http://web.me.com/${username}/?webdav-method=truthget&depth=infinity"
grep -oE "http://web\.me\.com\/[^\"]+" "$userdir/webdav-feed.xml" > "$userdir/urls.txt"
count=$( cat "$userdir/urls.txt" | wc -l )
echo " done."

echo -n " - Downloading (${count} files)..."
$WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" -i "$userdir/urls.txt" -O /dev/null \
    --warc-file="$userdir/web-me-com-$username" --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="mobileme: web.me.com, ${username}"
echo " done."

rm "${userdir}/.incomplete"

