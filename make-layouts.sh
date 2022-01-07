#!/usr/bin/env bash

set -o errexit

echo Setting up layouts

git clone --single-branch --branch main https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/nmos-doc-layouts .layouts
rm -rf _layouts assets
mv .layouts/_layouts .
mv .layouts/assets .
[[ ! -d _includes ]] && mkdir _includes # nmos repo already has it
mv .layouts/_includes/* _includes/
rm -rf .layouts
