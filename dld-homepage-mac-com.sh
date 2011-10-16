#!/bin/bash
#
# Script for downloading the contents of homepage.me.com for one user.
#
# Usage:   dld-homepage-me-com.sh ${USERNAME}
#
# Version 3. Now only for homepage.mac.com.
#    Scrapped PhantomJS, not really necessary for homepage.mac.com.
# Version 2. Added homepage.mac.com.
# Version 1.
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
domain="homepage.mac.com"
userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/homepage"

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
echo -n " - Running wget (takes a while)..."

$WGET_WARC -U "$USER_AGENT" -nv -o "$userdir/wget.log" \
    --directory-prefix="$userdir/files/" \
    -r -l inf --no-remove-listing \
    --page-requisites "http://homepage.mac.com/$username/" \
    --warc-file="$userdir/homepage-mac-com-$username" --warc-max-size=inf \
    --warc-header="operator: Archive Team" \
    --warc-header="mobileme: homepage.mac.com, ${username}"
rm -rf "$userdir/files/"

echo " done."
echo -n " - Result: "
du -hs "$userdir/homepage-mac-com-$username"*

rm "${userdir}/.incomplete"

