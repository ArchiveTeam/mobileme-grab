#!/bin/bash
#
# Script for downloading the contents of gallery.me.com for one user.
#
# This script makes one single large zip file for each gallery, which
# can cause problems when downloading very large galleries.
#
# Usage:   dld-gallery-me-com.sh ${USERNAME}
#
#
# Version 1.
#

USER_AGENT="AT"

username="$1"

userdir="data/${username:0:1}/${username:0:2}/${username:0:3}/${username}/gallery"

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


curl "http://gallery.me.com/${username}?webdav-method=truthget&feedfmt=json&depth=Infinity" \
     --silent \
     --user-agent "${USER_AGENT}" \
     --dump-header "${userdir}/index.json.headers" \
   > "${userdir}/index.json"

images=( `grep -o -E '"(largeImageUrl|videoUrl)"\s*:\s*"http:[^"]+"' "${userdir}/index.json" | grep -o -E 'http://gallery[^"]+' `)
echo "  - ${#images[@]} images"

if [[ ${#images[@]} -eq 0 ]]
then
  rm "${userdir}/.incomplete"
  exit 0
fi

echo '<?xml version="1.0" encoding="utf-8" ?><ziplist xmlns="http://user.mac.com/properties/">' > "${userdir}/ziplist.xml"
for image_url in ${images[@]}
do
  image_path=${image_url/#http:\/\/gallery.me.com\//}
  image_path=${image_path/%\/large.jpg/.jpg}
  image_path=${image_path/%\/web.jpg/.jpg}
  image_path=${image_path/%\/video.MOV/.MOV}
  echo "<entry><name>${image_path}</name><href>${image_url}</href></entry>" >> "${userdir}/ziplist.xml"
done
echo '</ziplist>' >> "${userdir}/ziplist.xml"

echo "  - Requesting zip file (can take a while)"
curl "http://gallery.me.com/${username}?webdav-method=ZIPLIST" \
    --data "@${userdir}/ziplist.xml" \
    --header "Content-Type: text/xml; charset=\"utf-8\"" \
    --silent \
    --user-agent "${USER_AGENT}" \
    --dump-header "${userdir}/ziplist-response.xml.headers" \
  > "${userdir}/ziplist-response.xml"

grep "<status>HTTP" "${userdir}/ziplist-response.xml" | grep -v -q "200 OK"
has_errors=$?

if [[ $has_errors -eq 0 ]]
then
  echo "  - There was a problem generating the zip file. File may be incomplete."
fi

zip_token=`grep -i "X-Zip-Token: " "${userdir}/ziplist-response.xml.headers" | cut --delimiter=" " -f 2 | grep -o -E "\S+"`
if [[ $zip_token =~ [a-z0-9]+ ]]
then
  echo "  - Downloading zip file"

  curl "http://gallery.me.com/${username}?webdav-method=ZIPGET&token=${zip_token}" \
      --user-agent "${USER_AGENT}" \
      --dump-header "${userdir}/download.zip.headers" \
    > "${userdir}/download.zip"
fi

rm "${userdir}/.incomplete"

