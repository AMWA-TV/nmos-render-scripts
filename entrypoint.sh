#!/bin/sh -l

export PAGES_REPO_NWO="$GITHUB_REPOSITORY"
git clone --single-branch "https://github.com/$GITHUB_REPOSITORY" /github-repo
cd /github-repo/.render || exit
chmod 777 .
ln -s /.scripts .scripts
make build
make upload
