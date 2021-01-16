#!/usr/bin/env bash

echo Removing source_repo...
rm -rf source_repo 

echo Building site...
bundle exec jekyll build

echo Removing Markdown...
find _site -name '*.md' -exec rm {} \;
