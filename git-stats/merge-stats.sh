#!/bin/bash

# Navigate to the repository directory
pushd $1 > /dev/null || { echo "Repository not found"; exit 1; }
BRANCH=${2:-main}
START_DATE=${START_DATE:=2024-07-01}
END_DATE=${END_DATE:=2024-10-01}
MIN_SECS=${MIN_SECS:=432000} # 5 days
MAX_SECS=${MAX_SECS:=2160000} # 30 days

echo -n "@$BRANCH[$START_DATE:$END_DATE] [count|min|max|avg|media] $1 "
git fetch origin $BRANCH staging > /dev/null 2>&1 || { echo "Failed to fetch repository $1"; exit 1; }

merges=`git log --merges --pretty=format:"%h;%ct" --author='^(?!github-actions).*$' --perl-regexp --since="$START_DATE" --before="$END_DATE" origin/$BRANCH`
durations=()
for merge in $merges; do
    sha=`echo $merge | cut -d';' -f1`
    closed=`echo $merge | cut -d';' -f2`
    opened=`git log "$sha^1..$sha^2" --format="%ct" | tail -1`
    duration=$((closed-opened))
    if [ $duration -lt $MIN_SECS ]; then
        continue
    fi
    if [ $duration -gt $MAX_SECS ]; then
        continue
    fi
    durations+=($duration)
done
echo ${durations[@]}| python -c "
import sys,statistics;\
    ns=list(map(lambda x: x/86400, map(int, sys.stdin.readline().split())));\
    print(\
        len(ns),\
        round(min(ns),5),\
        round(max(ns),2),\
        round(statistics.mean(ns),2),
        round(statistics.median(ns),2)\
    )\
"
popd > /dev/null
