#!/usr/bin/env bash

shopt -s globstar nullglob

echo Removing source_repo...
rm -rf source_repo/

echo Renaming files to prevent zero-length issue...
find branches releases -type f \( -name '*.png' -o -name '*.js' -o -name '*.css' \) -exec mv {} {}.notzero \;

echo Building site...
bundle exec jekyll build

echo Removing Markdown...
find _site -name '*.md' -exec rm {} \;

echo Renaming files back...
for i in _site/**/*.notzero; do
	mv "$i" "${i%%.notzero}"
done

echo Checking for zero length files...
find _site -size 0 -print
