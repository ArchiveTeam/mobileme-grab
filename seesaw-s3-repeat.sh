#!/bin/bash
# Seesaw script uploading to s3.us.archive.org
#
# THIS IS FOR BIG DOWNLOADERS ONLY.
# Please use the normal seesaw.sh script or ask on IRC.
#

youralias="$1"
accesskey="$2"
secret="$3"

if [[ -z $youralias ]] || [[ -z $accesskey ]] || [[ -z $secret ]]
then
  echo "Please use the normal seesaw.sh script or ask on IRC."
  echo "No alias, accesskey or secret given."
  exit 2
fi

while [ ! -f STOP ]
do
  echo "Downloading script"
  r=$RANDOM
  curl -k "https://raw.github.com/gist/a5ae1e8d6ede157b86a0" > new-seesaw-s3-$r.sh.tmp
  chmod +x new-seesaw-s3-$r.sh.tmp
  mv new-seesaw-s3-$r.sh.tmp seesaw-s3.sh
  ./seesaw-s3.sh $youralias $accesskey $secret
done

