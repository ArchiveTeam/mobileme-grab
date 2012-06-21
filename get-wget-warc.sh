#!/bin/bash
#
# This script downloads and compiles wget-warc.
#

# first, try to detect gnutls or openssl
CONFIGURE_SSL_OPT=""
if builtin type -p pkg-config &>/dev/null
then
  if pkg-config gnutls
  then
    echo "Compiling wget with GnuTLS."
    CONFIGURE_SSL_OPT="--with-ssl=gnutls"
  elif pkg-config openssl
  then
    echo "Compiling wget with OpenSSL."
    CONFIGURE_SSL_OPT="--with-ssl=openssl"
  fi
fi

TARFILE=wget-1.13.4.59-2b1dd.tar.bz2
TARDIR=wget-1.13.4.59-2b1dd

rm -rf $TARFILE $TARDIR/

# wget --no-check-certificate https://github.com/downloads/ArchiveTeam/mobileme-grab/$TARFILE
wget --no-check-certificate http://alpha.gnu.org/gnu/wget/wget-1.13.4.59-2b1dd.tar.bz2
tar xjf $TARFILE
cd $TARDIR/
if ./configure $CONFIGURE_SSL_OPT --disable-nls && make
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
  rm -rf $TARFILE $TARDIR/
else
  echo
  echo "wget-warc not successfully built."
  echo
fi

