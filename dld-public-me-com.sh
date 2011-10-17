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
     --dump-header "${userdir}/DAV.xml.headers" \
   > "$userdir/DAV.xml"

if [ $? -ne 0 ]
then

  echo "  - Error downloading index for ${username}."
  exit 1

else

  # grep for href, strip <D:href>/ix/
  resources=(`grep -o -E "<D:href>[^<]+" "$userdir/DAV.xml" | cut -c 13-`)

  echo -n "   - ${#resources[@]} files "

  for resource in ${resources[@]}
  do
    # do not download directories
    if [[ ! $resource =~ /$ ]]
    then
      # download resource
      outfile="${userdir}/${resource}"
      mkdir -p `dirname ${outfile}`
      curl "https://public.me.com/ix/${resource}" \
           --silent \
           --user-agent "${USER_AGENT}" \
           --dump-header "${outfile}.headers" \
         > "${outfile}"
      if [ $? -ne 0 ]
      then
        echo "  - Error downloading ${resource}"
        exit 1
      else
        echo -n "."
      fi
    fi
  done

  echo " done."

fi

rm "${userdir}/.incomplete"

exit 0

