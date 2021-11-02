#!/bin/sh -l

git clone --single-branch "https://github.com/$GITHUB_REPOSITORY" /github-repo
cd /github-repo/.render || exit
ln -s /.scripts .scripts
make build
make upload
