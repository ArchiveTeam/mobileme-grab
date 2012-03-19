#!/bin/bash
# Returns the file modification time.
#
# This script first tries stat from GNU coreutils, then stat from OS X/BSD.

path=$1

timestamp=0

# GNU coreutils stat
[[ $timestamp -eq 0 ]] && t=$( stat -c "%Y" $path 2>/dev/null ) && timestamp=$t

# OS X stat
[[ $timestamp -eq 0 ]] && t=$( stat -f "%m" $path 2>/dev/null ) && timestamp=$t

echo $timestamp

