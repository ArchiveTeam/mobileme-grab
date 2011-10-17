#!/bin/bash
#
# Script for downloading the contents of a .me.com domain for one user.
#
# Usage:   dld-me-com.sh ${DOMAIN} ${USERNAME}
# where DOMAIN is one of  gallery.me.com  web.me.com  public.me.com
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

domain="$1"
username="$2"
userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/${domain}"

if [[ -f "${userdir}/.incomplete" ]]
then
  echo "  Deleting incomplete result for ${domain}/${username}"
  rm -rf "${userdir}"
fi

if [[ -d "${userdir}" ]]
then
  echo "  Already downloaded ${domain}/${username}"
  exit 2
fi

mkdir -p "${userdir}"
touch "${userdir}/.incomplete"

echo "  Downloading ${domain}/${username}"

if [[ "$domain" =~ "public.me.com" ]]
then
  # public.me.com has real WebDAV
  echo -n "   - Discovering urls (XML)..."
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
    echo "  - ERROR."
    exit 1
  fi
  echo " done."

  # grep for href, strip <D:href>/ix/
  grep -o -E "<D:href>[^<]+" "$userdir/webdav-feed.xml" | cut -c 9- | awk '/[^\/]$/ { print "https://public.me.com" $1 }' > "$userdir/urls.txt"
  count=$( cat "$userdir/urls.txt" | wc -l )

else
  # web.me.com and gallery.me.com use query-string WebDAV
  echo -n "   - Discovering urls (JSON)..."
  curl "http://${domain}/${username}/?webdav-method=truthget&feedfmt=json&depth=Infinity" \
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
  curl "http://${domain}/${username}/?webdav-method=truthget&depth=Infinity" \
       --silent \
       --user-agent "${USER_AGENT}" \
     > "$userdir/webdav-feed.xml"
  if [ $? -ne 0 ]
  then
    echo " ERROR."
    exit 1
  fi
  echo " done."

  grep -oE "http://${domain}/[^/]+/[^\"]+" "$userdir/webdav-feed.json" > "$userdir/urls.txt"
  echo "http://${domain}/${username}/?webdav-method=truthget&feedfmt=json&depth=Infinity" >> "$userdir/urls.txt"
  echo "http://${domain}/${username}/?webdav-method=truthget&depth=Infinity" >> "$userdir/urls.txt"
  count=$( cat "$userdir/urls.txt" | wc -l )
fi

echo -n "   - Downloading (${count} files)..."
$WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" -i "$userdir/urls.txt" -O /dev/null \
    --no-check-certificate \
    --warc-file="$userdir/${domain}-$username" --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="mobileme: ${domain}, ${username}"
result=$?
if [ $result -ne 0 ] && [ $result -ne 8 ]
then
  echo "ERROR ($result)."
  exit 1
fi
echo " done."

echo -n "   - Result: "
du -hs "$userdir/${domain}-$username"* | cut -f 1

rm "${userdir}/.incomplete"

exit 0

