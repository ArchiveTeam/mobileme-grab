#!/usr/bin/env python
#
# Script for downloading the contents of gallery.me.com for one user.
#
# This script creates a separate zip file for each album, which should
# make it possible to download very large galleries.
#
# Usage:   dld-gallery-me-com.py ${USERNAME}
#
#
# Version 2. Better use of exit codes.
# Version 1.
#

import httplib
import json
from os import system
import os.path
import sys
import shutil
from xml.dom.minidom import parseString, getDOMImplementation


def slugify(value):
  '''
  Normalizes string, converts to lowercase, removes non-alpha characters,
  and converts spaces to hyphens.
  '''
  import unicodedata
  import re
  value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore')
  value = unicode(re.sub(r'[^\w\s-]', '', value).strip().lower())
  value = unicode(re.sub(r'[-\s]+', '-', value))
  return value


username = sys.argv[1]

userdir = "data/%s/%s/%s/%s/gallery" % (username[0:1], username[0:2], username[0:3], username)

if os.path.isfile(userdir + "/.incomplete"):
  print "  Deleting incomplete result for gallery.me.com/%s" % username
  shutil.rmtree(userdir)

if os.path.isdir(userdir):
  print "  Already downloaded gallery.me.com/%s" % username
  sys.exit(2)

os.makedirs(userdir)
open(userdir + "/.incomplete", "w").close

print '  Downloading gallery.me.com/%s' % username

conn = httplib.HTTPConnection('gallery.me.com')

conn.request('GET', '/%s?webdav-method=truthget&feedfmt=json&depth=Infinity' % username)
resp = conn.getresponse()

if not resp.status == 200:
  print "  Error: %s %s" % (resp.status, resp.reason)
  conn.close()
  sys.exit(1)

else:
  doc = json.load(resp)
  albums = dict()
  for record in doc['records']:
    if record['type'] == 'Photo':
      if record['album'] not in albums:
        albums[record['album']] = dict(photos=[])
      albums[record['album']]['photos'].append(record)
    else:
      if record['guid'] not in albums:
        albums[record['guid']] = dict(photos=[])
      albums[record['guid']]['title'] = record['title']
  conn.close
  
  albumnames = set()
  for album_guid, album_data in albums.items():
    album_name = album_guid
    if 'title' in album_data:
      album_name = album_data['title']
    album_name = slugify(album_name)
    i = 1
    while album_name in albumnames:
      album_name = '%s-%d' % (album_name, i)
      i += 1
    albumnames.add(album_name)
    
    zipdoc = getDOMImplementation().createDocument(None, 'ziplist', None)
    root = zipdoc.documentElement
    # silly xml.dom.minidom doesn't do namespaces
    root.setAttribute('xmlns', 'http://user.mac.com/properties/')
    
    for photo in album_data['photos']:
      url = None
      if 'largeImageUrl' in photo:
        url = photo['largeImageUrl']
      elif 'videoUrl' in photo:
        url = photo['videoUrl']
      elif 'webImageUrl' in photo:
        url = photo['webImageUrl']
      else:
        print photo
      
      name = url
      name = name.replace('http://gallery.me.com/', '')
      name = name.replace('/large.jpg', '.jpg')
      name = name.replace('/web.jpg', '.jpg')
      name = name.replace('/video.MOV', '.MOV')
      
      entry = zipdoc.createElement('entry')
      el = zipdoc.createElement('name')
      el.appendChild(zipdoc.createTextNode(name))
      entry.appendChild(el)
      el = zipdoc.createElement('href')
      el.appendChild(zipdoc.createTextNode(url))
      entry.appendChild(el)
      root.appendChild(entry)
    
    print '   - Requesting zip for album %s (%d photos)' % (album_name, len(album_data['photos']))
    conn = httplib.HTTPConnection('gallery.me.com')
    conn.request('POST', '/%s?webdav-method=ZIPLIST' % username, zipdoc.toxml(), {'Content-Type':'text/xml; charset="utf-8"'})
    resp = conn.getresponse()
    zip_token = resp.getheader('X-Zip-Token')
    respdoc = parseString(resp.read())
    conn.close
    
    errors = False
    for status in respdoc.getElementsByTagName('status'):
      if status.firstChild.nodeValue != 'HTTP/1.1 200 OK':
        if status.parentNode.getElementsByTagName('href')[0].firstChild is None:
          print "   - Error zipping (no files, perhaps?)"
        else:
          print "   - Error zipping %s" % status.parentNode.getElementsByTagName('href')[0].firstChild.nodeValue
        errors = True
        sys.exit(2)
    
    if not errors:
      print '   - Downloading zip for album %s' % album_name
      ret = system("curl 'http://gallery.me.com/%s?webdav-method=ZIPGET&token=%s' > '%s/%s.zip'" % (username, zip_token, userdir, album_name))
      if not ret == 0:
        print "   - Error downloading zip file."
        sys.exit(1)

  print "   - Done."
  os.unlink(userdir + "/.incomplete")

  sys.exit(0)

