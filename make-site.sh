#!/usr/bin/env bash

set -o errexit
shopt -s globstar nullglob

# shellcheck source=get-config.sh
. .scripts/get-config.sh

echo Removing source-repo
rm -rf source-repo

if [[ "$AMWA_ID" == "NMOS" ]]; then
    echo Making _data/specs.json
    .scripts/make-specs-json.sh
fi

echo Renaming files to prevent zero-length issue
for i in {branches,releases}/**/*.{png,js,css}; do
	mv "$i" "$i.notzero"
done

echo Building site
bundle exec jekyll build

echo Removing Markdown
find _site -name '*.md' -exec rm {} \;

echo Renaming files back
for i in _site/**/*.notzero; do
	mv "$i" "${i%%.notzero}"
done

echo Checking for zero length files
find _site -size 0 -print
