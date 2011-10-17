#!/bin/bash
#
# Script for downloading the contents of gallery.me.com for one user.
#
# Usage:   dld-gallery-me-com.sh ${USERNAME}
#

if [[ ! -x $WGET_WARC ]]
then
  WGET_WARC=$(which wget)
  if ! $WGET_WARC --help | grep -q WARC
  then
    echo "${WGET_WARC} does not support WARC. Set the WGET_WARC environment variable."
    exit 3
  fi
fi

if [[ ! -x $WGET_WARC ]]
then
  echo "wget-warc not found. Set the WGET_WARC environment variable."
  exit 3
fi

USER_AGENT="AT"

username="$1"
userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/gallery"

if [[ -f "${userdir}/.incomplete" ]]
then
  echo "  Deleting incomplete result for gallery.me.com/${username}"
  rm -rf "${userdir}"
fi

if [[ -d "${userdir}" ]]
then
  echo "  Already downloaded gallery.me.com/${username}"
  exit 2
fi

mkdir -p "${userdir}"
touch "${userdir}/.incomplete"

echo "  Downloading gallery.me.com/${username}"

echo -n "   - Discovering urls (JSON)..."
curl "http://gallery.me.com/${username}/?webdav-method=truthget&feedfmt=json&depth=Infinity" \
     --silent --fail \
     --user-agent "${USER_AGENT}" \
   > "$userdir/webdav-feed.json"
result=$?
if [ $result -ne 0 ]
then
  echo " ERROR."
  exit 1
fi
echo " done."

echo -n "   - Discovering urls (XML)..."
curl "http://gallery.me.com/${username}/?webdav-method=truthget&depth=Infinity" \
     --silent \
     --user-agent "${USER_AGENT}" \
   > "$userdir/webdav-feed.xml"
if [ $? -ne 0 ]
then
  echo " ERROR."
  exit 1
fi
echo " done."

grep -oE 'http://gallery.me.com/[^/]+/[^"]+' "$userdir/webdav-feed.json" > "$userdir/urls.txt"
echo "http://gallery.me.com/${username}/?webdav-method=truthget&feedfmt=json&depth=Infinity" >> "$userdir/urls.txt"
echo "http://gallery.me.com/${username}/?webdav-method=truthget&depth=Infinity" >> "$userdir/urls.txt"
count=$( cat "$userdir/urls.txt" | wc -l )

echo -n "   - Downloading (${count} files)..."
$WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" -i "$userdir/urls.txt" -O /dev/null \
    --no-check-certificate \
    --warc-file="$userdir/gallery-me-com-$username" --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="mobileme: gallery.me.com, ${username}"
result=$?
if [ $result -ne 0 ] && [ $result -ne 8 ]
then
  echo "ERROR ($result)."
  exit 1
fi
echo " done."

rm "${userdir}/.incomplete"

exit 0

