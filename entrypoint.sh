#!/bin/sh -l


git clone --single-branch --branch publish-docker-test "https://github.com/$GITHUB_REPOSITORY" /github-repo
cd /github-repo/.render || exit
make build-tools
make build
make upload
/bin/sh
