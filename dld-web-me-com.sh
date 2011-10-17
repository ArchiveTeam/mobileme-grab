#!/bin/bash
#
# Script for downloading the contents of web.me.com for one user.
#
# Usage:   dld-web-me-com.sh ${USERNAME}
#
# Version 4. Better use of exit codes.
# Version 3. Started with a new script for web.me.com.
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
userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/web"

if [[ -f "${userdir}/.incomplete" ]]
then
  echo "  Deleting incomplete result for web.me.com/${username}"
  rm -rf "${userdir}"
fi

if [[ -d "${userdir}" ]]
then
  echo "  Already downloaded web.me.com/${username}"
  exit 2
fi

mkdir -p "${userdir}"
touch "${userdir}/.incomplete"

echo "  Downloading web.me.com/${username}"

echo -n "   - Discovering urls..."
curl -s -A "$USER_AGENT" "http://web.me.com/${username}/?webdav-method=truthget&depth=infinity" > "$userdir/webdav-feed.xml"
if [ $? -ne 0 ]
then
  echo " ERROR."
  exit 1
fi
if grep -q -E "^Not Found$" "$userdir/webdav-feed.xml"
then
  echo " not found." 
  exit 0
fi
grep -oE "http://web\.me\.com\/[^\"]+" "$userdir/webdav-feed.xml" > "$userdir/urls.txt"
count=$( cat "$userdir/urls.txt" | wc -l )
echo " done."

echo -n "   - Downloading (${count} files)..."
$WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" -i "$userdir/urls.txt" -O /dev/null \
    --warc-file="$userdir/web-me-com-$username" --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="mobileme: web.me.com, ${username}"
result=$?
if [ $result -ne 0 ] && [ $result -ne 8 ]
then
  echo "ERROR ($result)."
  exit 1
fi
echo " done."

rm "${userdir}/.incomplete"

exit 0

