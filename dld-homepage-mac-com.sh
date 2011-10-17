#!/bin/bash
#
# Script for downloading the contents of homepage.me.com for one user.
#
# Usage:   dld-homepage-me-com.sh ${USERNAME}
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
userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/homepage.mac.com"

if [[ -f "${userdir}/.incomplete" ]]
then
  echo "  Deleting incomplete result for homepage.mac.com/${username}"
  rm -rf "${userdir}"
fi

if [[ -d "${userdir}" ]]
then
  echo "  Already downloaded homepage.mac.com/${username}"
  exit 2
fi

mkdir -p "${userdir}"
touch "${userdir}/.incomplete"

echo "  Downloading homepage.mac.com/${username}"
echo -n "   - Running wget --mirror (takes a while)..."

$WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" \
    --directory-prefix="$userdir/files/" \
    -r -l inf --no-remove-listing \
    --page-requisites "http://homepage.mac.com/$username/" \
    --warc-file="$userdir/homepage.mac.com-$username" --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="mobileme: homepage.mac.com, ${username}"
result=$?
if [ $result -ne 0 ] && [ $result -ne 8 ]
then
  echo " ERROR ($result)."
  exit 1
fi
rm -rf "$userdir/files/"

echo " done."
echo -n "   - Result: "
du -hs "$userdir/homepage.mac.com-$username"* | cut -f 1

rm "${userdir}/.incomplete"

exit 0

