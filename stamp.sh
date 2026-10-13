#!/bin/sh
# Stamp index.html with the current commit and time, so Settings shows which
# build is actually running. Run before committing a change.
sha=$(git rev-parse --short HEAD)
when=$(date -u '+%Y-%m-%d %H:%M UTC')
perl -0pi -e "s/const BUILD=\{stamp:'[^']*',sha:'[^']*'\};/const BUILD={stamp:'$when',sha:'$sha'};/" index.html
echo "stamped $when ($sha)"
