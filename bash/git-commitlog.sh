#!/bin/sh

# This script pulls the commits from the current git repo. The primary purpose of this script
# is to document a few standard options and the SED command to make the date Excel usable.
# Users are expected to modify the timeframe (--since "4 weeks ago") as appropriate.

# cd to the git repo you want to check

git fetch
echo 'user|date|commit|summary'

git log --all --since "4 weeks ago" --pretty="format:%ae|%ai|%h|%s" \
    | sed 's/|\([0-9]*-[0-9]*-[0-9]*\) [0-9]*:[0-9]*:[0-9]* .[0-9]*|/|\1|/' \
    | grep -v "Automatic merge from" \
    | grep -v "Merge pull request #" \
    | grep -v "Pull request #"
