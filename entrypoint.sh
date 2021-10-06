#!/bin/sh -l


git clone "https://github.com/$GITHUB_REPOSITORY" /github-repo
cd /github-repo/.render
make build-tools
make build
make upload
/bin/sh
