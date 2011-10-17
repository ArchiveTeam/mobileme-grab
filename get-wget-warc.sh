#!/bin/bash
#
# This script downloads and compiles wget-warc.
#

rm -rf wget-warc-20110809.tar.bz2 wget-1.12-2507-dirty/

wget https://github.com/downloads/alard/wget-warc/wget-warc-20110809.tar.bz2
tar xjf wget-warc-20110809.tar.bz2
cd wget-1.12-2507-dirty/
if ./configure && make
then
  cp src/wget ../wget-warc
  cd ../
  echo
  echo
  echo "###################################################################"
  echo
  echo "wget-warc successfully built."
  echo
  ./wget-warc --help | grep -iE "gnu|warc"
  rm -rf wget-warc-20110809.tar.bz2 wget-1.12-2507-dirty/
else
  echo
  echo "wget-warc not successfully built."
  echo
fi

