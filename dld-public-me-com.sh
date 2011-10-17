#!/bin/bash
#
# Script for downloading the contents of public.me.com for one user.
#
# Usage:   dld-public-me-com.sh ${USERNAME}
#
#
# Version 2. Better use of exit codes.
# Version 1.
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
userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/public"

if [[ -f "${userdir}/.incomplete" ]]
then
  echo "  Deleting incomplete result for public.me.com/${username}"
  rm -rf "${userdir}"
fi

if [[ -d "${userdir}" ]]
then
  echo "  Already downloaded public.me.com/${username}"
  exit 2
fi

mkdir -p "${userdir}"
touch "${userdir}/.incomplete"

echo "  Downloading public.me.com/${username}"

# WebDAV's PROPFIND is cool: with "Depth: infinity", it will give us the
# complete contents of the user's directory with one request
curl "https://public.me.com/ix/${username}/" \
     --silent \
     --request PROPFIND \
     --header "Content-Type: text/xml; charset=\"utf-8\"" \
     --header "Depth: infinity" \
     --data '<?xml version="1.0" encoding="utf-8"?><DAV:propfind xmlns:DAV="DAV:"><DAV:allprop/></DAV:propfind>' \
     --user-agent "${USER_AGENT}" \
   > "$userdir/webdav-feed.xml"

if [ $? -ne 0 ]
then

  echo "  - Error downloading index for ${username}."
  exit 1

else

  # grep for href, strip <D:href>/ix/
  grep -o -E "<D:href>[^<]+" "$userdir/webdav-feed.xml" | cut -c 9- | awk '/[^\/]$/ { print "https://public.me.com" $1 }' > "$userdir/urls.txt"
  count=$( cat "$userdir/urls.txt" | wc -l )

  echo -n "   - Downloading (${count} files)..."
  $WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" -i "$userdir/urls.txt" -O /dev/null \
      --no-check-certificate \
      --warc-file="$userdir/public-me-com-$username" --warc-max-size=inf \
      --warc-header="operator: Archive Team" \
      --warc-header="mobileme: public.me.com, ${username}"
  result=$?
  if [ $result -ne 0 ] && [ $result -ne 8 ]
  then
    echo "ERROR ($result)."
    exit 1
  fi
  echo " done."

fi

rm "${userdir}/.incomplete"

exit 0

