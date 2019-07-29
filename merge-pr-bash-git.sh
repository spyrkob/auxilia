#!/bin/bash
#
# This script expects:
#
# 0. jq commandline JSON processor, see https://stedolan.github.io/jq
#
# 1. .netrc with configuration as follows:
#    machine	api.github.com
#    login	UID
#    password	ACCESS_TOKEN
#
# 2. Remote URLs in your jboss-eap clone using git protocol instead of https, ie. something like:
#    origin	git@github.com:istudens/jboss-eap7.git (fetch)
#    origin	git@github.com:istudens/jboss-eap7.git (push)
#    upstream	git@github.com:jbossas/jboss-eap7.git (fetch)
#    upstream	git@github.com:jbossas/jboss-eap7.git (push)
#
# 3. In case of remotes like above, the first parameter should be 'upstream' and the second parameter should be a number of PR being merged.
#
set -e
if [ $# != 2 ]; then
    echo 1>&2 "Usage: $0 <remote> <pr>"
    exit 1
fi
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE=$1
PR=$2
echo "Merging $PR from $REMOTE onto $BRANCH"
FETCH_URL=$(git remote -v|grep $REMOTE|grep "fetch"|cut -f2|cut -d" " -f1)
OWNER=$(echo $FETCH_URL | cut -d: -f2 | cut -d/ -f1)
REPO=$(echo $FETCH_URL | cut -d: -f2 | cut -d/ -f2)
REPO=$(echo $REPO | sed 's/\.git$//')
PULL=$(curl -s -n https://api.github.com/repos/$OWNER/$REPO/pulls/$PR)
MSG="Merge pull request #$PR from $(echo $PULL | jq -r .head.label)
$(echo $PULL | jq -r .title)"
echo "$MSG"
echo -n "Continue..." && read _
set -x
git fetch $REMOTE pull/$PR/head
git merge --no-ff -m "$MSG" FETCH_HEAD