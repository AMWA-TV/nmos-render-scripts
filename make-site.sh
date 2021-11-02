#!/usr/bin/env bash

set -o errexit
shopt -s globstar nullglob

echo Removing source-repo
rm -rf source-repo

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
