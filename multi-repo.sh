#!/bin/sh -l

for repo in "$@"; do
	echo
	echo "----- Processing $repo -----"
	echo
	rm -rf /github-repo
	GITHUB_REPOSITORY="AMWA-TV/$repo" /entrypoint.sh
done