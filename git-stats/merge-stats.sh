#!/bin/bash

# Navigate to the repository directory
pushd $1 > /dev/null || { echo "Repository not found"; exit 1; }
BRANCH=${2:-staging}
$FROM_DATE=${FROM_DATE:-2024-07-01}
$START_DT=${TO_DATE:-2024-10-01}
$END_DT=${TO_DATE:-2024-10-01}

echo "Fetching repository $1 @$BRANCH [$START_DT-$END_DT]..."
git fetch origin $BRANCH staging > /dev/null 2>&1 || { echo "Failed to fetch repository $1"; exit 1; }

merges=`git log --merges --pretty=format:"%h;%ct" --author='^(?!github-actions).*$' --perl-regexp --since="$START_DT" --before="$END_DT" origin/$BRANCH`
durations=()
for merge in $merges; do
    sha=`echo $merge | cut -d';' -f1`
    closed=`echo $merge | cut -d';' -f2`
    opened=`git log "$sha^1..$sha^2" --format="%ct" | tail -1`
    duration=$((closed-opened))
    durations+=($duration)
done
#echo ${durations[@]}
echo ${durations[@]}| python -c "
import sys,statistics;\
    ns=list(map(lambda x: x/3600, map(int, sys.stdin.readline().split())));\
    print('count/min/max/avg/median:',\
        len(ns),\
        round(min(ns),5),\
        round(max(ns),2),\
        round(statistics.mean(ns),2),
        round(statistics.median(ns),2)\
    )\
"
popd > /dev/null
